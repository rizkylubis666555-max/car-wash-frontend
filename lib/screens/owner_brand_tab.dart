import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/vehicle_brand_service.dart';
import '../widgets/owner_config_section_header.dart';
import 'detailed_view_screen.dart';

class OwnerBrandTab extends StatefulWidget {
  const OwnerBrandTab({super.key});

  @override
  State<OwnerBrandTab> createState() => _OwnerBrandTabState();
}

class _OwnerBrandTabState extends State<OwnerBrandTab> {
  final VehicleBrandService _service = VehicleBrandService();
  List<Map<String, dynamic>> _brands = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _brands = await _service.fetchVehicleBrands();
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

  Future<void> _showBrandForm([Map<String, dynamic>? brand]) async {
    final controller = TextEditingController(
      text: brand?['name'] as String? ?? '',
    );
    var isActive = brand?['is_active'] != false;
    String? errorMessage;
    var isSubmitting = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(brand == null ? 'Tambah merek' : 'Ubah merek'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama merek',
                  border: OutlineInputBorder(),
                ),
              ),
              if (brand != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Merek aktif'),
                  subtitle: Text(
                    isActive
                        ? 'Merek tersedia pada input kendaraan baru.'
                        : 'Merek tidak tersedia pada input kendaraan baru.',
                  ),
                  value: isActive,
                  onChanged: isSubmitting
                      ? null
                      : (value) => setDialogState(() {
                          isActive = value;
                        }),
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
                          () => errorMessage = 'Nama merek wajib diisi.',
                        );
                        return;
                      }
                      setDialogState(() {
                        isSubmitting = true;
                        errorMessage = null;
                      });
                      try {
                        if (brand == null) {
                          final existingIds = _brands
                              .map((item) => item['id'].toString())
                              .toSet();
                          try {
                            await _service.createVehicleBrand(name);
                          } catch (error) {
                            if (error is! ApiException ||
                                !error.hasUnknownWriteOutcome) {
                              rethrow;
                            }
                            final savedBrands = await _service
                                .fetchVehicleBrands();
                            final wasSaved = savedBrands.any(
                              (item) =>
                                  !existingIds.contains(
                                    item['id'].toString(),
                                  ) &&
                                  item['name'] == name,
                            );
                            if (!wasSaved) {
                              rethrow;
                            }
                          }
                        } else {
                          try {
                            await _service.updateVehicleBrand(
                              brand['id'] as int,
                              name,
                              isActive: isActive,
                            );
                          } catch (error) {
                            if (error is! ApiException ||
                                !error.hasUnknownWriteOutcome) {
                              rethrow;
                            }
                            final savedBrands = await _service
                                .fetchVehicleBrands();
                            final savedBrand = savedBrands.where(
                              (item) => item['id'] == brand['id'],
                            );
                            if (savedBrand.isEmpty ||
                                savedBrand.first['name'] != name ||
                                savedBrand.first['is_active'] != isActive) {
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
      await _loadBrands();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage == null
                  ? 'Merek berhasil disimpan.'
                  : 'Merek berhasil disimpan, tetapi daftar gagal dimuat ulang: $_errorMessage',
            ),
          ),
        );
      }
    }
  }

  Future<void> _deactivate(Map<String, dynamic> brand) async {
    await _setBrandActive(brand, false);
  }

  Future<void> _activate(Map<String, dynamic> brand) async {
    await _setBrandActive(brand, true);
  }

  Future<void> _setBrandActive(
    Map<String, dynamic> brand,
    bool isActive,
  ) async {
    final actionLabel = isActive ? 'aktifkan' : 'nonaktifkan';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${isActive ? 'Aktifkan' : 'Nonaktifkan'} merek?'),
        content: Text(
          isActive
              ? 'Merek ${brand['name']} akan tersedia kembali pada input kasir.'
              : 'Merek ${brand['name']} tidak akan muncul pada input kasir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isActive ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      try {
        if (isActive) {
          await _service.updateVehicleBrand(
            brand['id'] as int,
            brand['name'] as String,
            isActive: true,
          );
        } else {
          await _service.deactivateVehicleBrand(brand['id'] as int);
        }
      } catch (error) {
        if (error is! ApiException || !error.hasUnknownWriteOutcome) {
          rethrow;
        }
        final savedBrands = await _service.fetchVehicleBrands();
        final savedBrand = savedBrands.where(
          (item) => item['id'] == brand['id'],
        );
        if (savedBrand.isEmpty || savedBrand.first['is_active'] != isActive) {
          rethrow;
        }
      }
      await _loadBrands();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage == null
                  ? 'Merek berhasil ${isActive ? 'diaktifkan' : 'dinonaktifkan'}.'
                  : 'Merek berhasil $actionLabel, tetapi daftar gagal dimuat ulang: $_errorMessage',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal $actionLabel merek: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBrandForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah merek'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            OwnerConfigSectionHeader(
              title: 'Kelola merek',
              subtitle: 'Atur pilihan merek kendaraan pelanggan',
              icon: Icons.directions_car_rounded,
              itemCount: _brands.length,
              isLoading: _isLoading,
              onRefresh: _loadBrands,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _brands.isEmpty
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
                            onPressed: _loadBrands,
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBrands,
                      child: _brands.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: const [
                                SizedBox(height: 110),
                                Icon(
                                  Icons.directions_car_outlined,
                                  size: 48,
                                  color: Color(0xFF2369C8),
                                ),
                                SizedBox(height: 12),
                                Center(
                                  child: Text('Belum ada merek kendaraan.'),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 92),
                              itemCount: _brands.length,
                              itemBuilder: (context, index) {
                                final brand = _brands[index];
                                final isActive = brand['is_active'] == true;
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
                                        color: const Color(0xFFE5EFFF),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Icon(
                                        Icons.directions_car_filled_rounded,
                                        color: Color(0xFF2369C8),
                                      ),
                                    ),
                                    title: Text(
                                      brand['name'] as String? ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: OwnerConfigStatusBadge(
                                        isActive: isActive,
                                      ),
                                    ),
                                    onTap: () => openDetailedView(
                                      context,
                                      title: 'Detail Merek',
                                      data: brand,
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      tooltip: 'Tindakan merek',
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          _showBrandForm(brand);
                                        } else if (action == 'activate') {
                                          _activate(brand);
                                        } else if (action == 'deactivate') {
                                          _deactivate(brand);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Ubah'),
                                        ),
                                        if (isActive)
                                          const PopupMenuItem(
                                            value: 'deactivate',
                                            child: Text('Nonaktifkan'),
                                          )
                                        else
                                          const PopupMenuItem(
                                            value: 'activate',
                                            child: Text('Aktifkan'),
                                          ),
                                      ],
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
