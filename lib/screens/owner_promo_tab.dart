import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/catalog_service.dart';
import '../widgets/owner_config_section_header.dart';
import 'detailed_view_screen.dart';

class OwnerPromoTab extends StatefulWidget {
  const OwnerPromoTab({super.key});

  @override
  State<OwnerPromoTab> createState() => _OwnerPromoTabState();
}

class _OwnerPromoTabState extends State<OwnerPromoTab> {
  final CatalogService _service = CatalogService();
  List<Map<String, dynamic>> _promos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPromos();
  }

  Future<void> _loadPromos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _promos = await _service.fetchPromos();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showPromoForm([Map<String, dynamic>? promo]) async {
    final controller = TextEditingController(
      text: promo?['name'] as String? ?? '',
    );
    var isActive = promo?['is_active'] as bool? ?? true;
    var isSubmitting = false;
    String? errorMessage;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(promo == null ? 'Tambah promo' : 'Ubah promo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nama promo',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Promo aktif'),
                value: isActive,
                onChanged: (value) => setDialogState(() => isActive = value),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ketentuan: 5 cucian selesai berbayar mendapat 1 cucian gratis. Poin tidak kedaluwarsa.',
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        setDialogState(
                          () => errorMessage = 'Nama promo wajib diisi.',
                        );
                        return;
                      }
                      setDialogState(() {
                        isSubmitting = true;
                        errorMessage = null;
                      });
                      try {
                        if (promo == null) {
                          final existingIds = _promos
                              .map((item) => item['id'].toString())
                              .toSet();
                          try {
                            await _service.createPromo(name, isActive);
                          } catch (error) {
                            if (error is! ApiException ||
                                !error.hasUnknownWriteOutcome) {
                              rethrow;
                            }
                            final savedPromos = await _service.fetchPromos();
                            final wasSaved = savedPromos.any(
                              (item) =>
                                  !existingIds.contains(
                                    item['id'].toString(),
                                  ) &&
                                  item['name'] == name &&
                                  item['is_active'] == isActive,
                            );
                            if (!wasSaved) {
                              rethrow;
                            }
                          }
                        } else {
                          try {
                            await _service.updatePromo(
                              promo['id'] as int,
                              name,
                              isActive,
                            );
                          } catch (error) {
                            if (error is! ApiException ||
                                !error.hasUnknownWriteOutcome) {
                              rethrow;
                            }
                            final savedPromos = await _service.fetchPromos();
                            final savedPromo = savedPromos.where(
                              (item) => item['id'] == promo['id'],
                            );
                            if (savedPromo.isEmpty ||
                                savedPromo.first['name'] != name ||
                                savedPromo.first['is_active'] != isActive) {
                              rethrow;
                            }
                          }
                        }
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (error) {
                        if (dialogContext.mounted) {
                          setDialogState(() => errorMessage = error.toString());
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      }
                    },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (saved == true && mounted) {
      await _loadPromos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage == null
                  ? 'Promo berhasil disimpan.'
                  : 'Promo berhasil disimpan, tetapi daftar gagal dimuat ulang: $_errorMessage',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPromoForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah promo'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            OwnerConfigSectionHeader(
              title: 'Kelola promo',
              subtitle: 'Atur promo dan hadiah loyalitas member',
              icon: Icons.local_offer_rounded,
              itemCount: _promos.length,
              isLoading: _isLoading,
              onRefresh: _loadPromos,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _promos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _loadPromos,
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPromos,
                      child: _promos.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: const [
                                SizedBox(height: 110),
                                Icon(
                                  Icons.local_offer_outlined,
                                  size: 48,
                                  color: Color(0xFF2369C8),
                                ),
                                SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    'Belum ada promo. Tambahkan promo pertama.',
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 92),
                              itemCount: _promos.length,
                              itemBuilder: (context, index) {
                                final promo = _promos[index];
                                final isActive = promo['is_active'] == true;
                                return Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.fromLTRB(
                                      14,
                                      8,
                                      8,
                                      8,
                                    ),
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF8F74D1),
                                            Color(0xFF6851B5),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      promo['name'] as String? ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${promo['wash_threshold']} cucian berbayar • ${promo['free_washes']} gratis',
                                          ),
                                          const SizedBox(height: 6),
                                          OwnerConfigStatusBadge(
                                            isActive: isActive,
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () => openDetailedView(
                                      context,
                                      title: 'Detail Promo',
                                      data: promo,
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Ubah promo',
                                      onPressed: () => _showPromoForm(promo),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
