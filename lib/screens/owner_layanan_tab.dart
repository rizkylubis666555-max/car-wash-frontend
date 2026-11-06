import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/catalog_service.dart';
import '../widgets/owner_config_section_header.dart';
import 'detailed_view_screen.dart';

class OwnerLayananTab extends StatefulWidget {
  const OwnerLayananTab({super.key});

  @override
  State<OwnerLayananTab> createState() => _OwnerLayananTabState();
}

class _OwnerLayananTabState extends State<OwnerLayananTab> {
  final CatalogService _service = CatalogService();
  List<Map<String, dynamic>> _layanan = [];
  bool _isLoading = true;
  bool _hasLoadedLayanan = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLayanan();
  }

  Future<void> _loadLayanan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final layanan = await _service.fetchLayanan();
      if (mounted) {
        setState(() {
          _layanan = layanan;
          _hasLoadedLayanan = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showLayananForm([Map<String, dynamic>? layanan]) async {
    var name = layanan?['nama_layanan'] as String? ?? '';
    var rawPrice = layanan?['harga']?.toString() ?? '';
    var selectedVehicleType = layanan?['jenis_kendaraan'] as String? ?? 'motor';
    var isActive = layanan?['is_active'] != false;
    var isSubmitting = false;
    String? formError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(layanan == null ? 'Tambah layanan' : 'Ubah layanan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    onChanged: (value) => name = value,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama layanan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Jenis kendaraan'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        avatar: const Icon(Icons.two_wheeler, size: 18),
                        label: const Text('Motor'),
                        selected: selectedVehicleType == 'motor',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              selectedVehicleType = 'motor';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        avatar: const Icon(Icons.directions_car, size: 18),
                        label: const Text('Mobil'),
                        selected: selectedVehicleType == 'mobil',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              selectedVehicleType = 'mobil';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: rawPrice,
                    onChanged: (value) => rawPrice = value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Harga (Rp)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (layanan != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Layanan aktif'),
                      subtitle: Text(
                        isActive
                            ? 'Layanan tersedia untuk transaksi baru.'
                            : 'Layanan tidak tersedia untuk transaksi baru.',
                      ),
                      value: isActive,
                      onChanged: isSubmitting
                          ? null
                          : (value) => setDialogState(() {
                              isActive = value;
                            }),
                    ),
                  if (formError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      formError!,
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
                          final trimmedName = name.trim();
                          final price = int.tryParse(rawPrice);
                          if (trimmedName.isEmpty ||
                              price == null ||
                              price < 1) {
                            setDialogState(() {
                              formError =
                                  'Isi nama layanan dan harga lebih dari Rp 0.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            formError = null;
                          });
                          try {
                            if (layanan == null) {
                              final existingIds = _layanan
                                  .map((item) => item['id'].toString())
                                  .toSet();
                              try {
                                await _service.createLayanan(
                                  trimmedName,
                                  selectedVehicleType,
                                  price,
                                );
                              } catch (error) {
                                if (!_hasUnknownWriteOutcome(error) ||
                                    !_hasLoadedLayanan) {
                                  rethrow;
                                }

                                List<Map<String, dynamic>> savedServices;
                                try {
                                  savedServices = await _service.fetchLayanan();
                                } catch (verificationError) {
                                  throw ApiException(
                                    'Respons simpan tidak diterima dan hasilnya belum dapat dipastikan. Muat ulang daftar layanan sebelum mencoba lagi. $verificationError',
                                  );
                                }

                                final wasSaved = savedServices.any((item) {
                                  final id = item['id']?.toString();
                                  final savedPrice = item['harga'] is num
                                      ? (item['harga'] as num).toInt()
                                      : int.tryParse(
                                              item['harga']?.toString() ?? '',
                                            ) ??
                                            0;
                                  return id != null &&
                                      !existingIds.contains(id) &&
                                      item['nama_layanan'] == trimmedName &&
                                      item['jenis_kendaraan'] ==
                                          selectedVehicleType &&
                                      savedPrice == price;
                                });
                                if (!wasSaved) {
                                  rethrow;
                                }
                              }
                            } else {
                              try {
                                await _service.updateLayanan(
                                  layanan['id'] as int,
                                  trimmedName,
                                  selectedVehicleType,
                                  price,
                                  isActive: isActive,
                                );
                              } catch (error) {
                                if (!_hasUnknownWriteOutcome(error)) {
                                  rethrow;
                                }

                                final savedServices = await _service
                                    .fetchLayanan();
                                final savedService = savedServices.where(
                                  (item) => item['id'] == layanan['id'],
                                );
                                final savedPrice = savedService.isEmpty
                                    ? null
                                    : savedService.first['harga'] is num
                                    ? (savedService.first['harga'] as num)
                                          .toInt()
                                    : int.tryParse(
                                        savedService.first['harga']
                                                ?.toString() ??
                                            '',
                                      );
                                if (savedService.isEmpty ||
                                    savedService.first['nama_layanan'] !=
                                        trimmedName ||
                                    savedService.first['jenis_kendaraan'] !=
                                        selectedVehicleType ||
                                    savedPrice != price ||
                                    savedService.first['is_active'] !=
                                        isActive) {
                                  rethrow;
                                }
                              }
                            }

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (error) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                formError = error.toString();
                              });
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      await _loadLayanan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage == null
                  ? 'Layanan berhasil disimpan.'
                  : 'Layanan berhasil disimpan, tetapi daftar gagal dimuat ulang: $_errorMessage',
            ),
          ),
        );
      }
    }
  }

  bool _hasUnknownWriteOutcome(Object error) =>
      error is ApiException && error.hasUnknownWriteOutcome;

  Future<void> _deleteLayanan(Map<String, dynamic> layanan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus layanan?'),
        content: Text(
          'Layanan ${layanan['nama_layanan']} hanya dapat dihapus jika belum digunakan pada transaksi. Riwayat yang sudah ada akan tetap terlindungi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus layanan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      try {
        await _service.deleteLayanan(layanan['id'] as int);
      } catch (error) {
        if (!_hasUnknownWriteOutcome(error)) {
          rethrow;
        }

        List<Map<String, dynamic>> savedServices;
        try {
          savedServices = await _service.fetchLayanan();
        } catch (verificationError) {
          throw ApiException(
            'Respons penghapusan tidak diterima dan hasilnya belum dapat dipastikan. Muat ulang daftar layanan sebelum mencoba lagi. $verificationError',
          );
        }
        if (savedServices.any((item) => item['id'] == layanan['id'])) {
          rethrow;
        }
      }

      await _loadLayanan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage == null
                  ? 'Layanan berhasil dihapus.'
                  : 'Layanan berhasil dihapus, tetapi daftar gagal dimuat ulang: $_errorMessage',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  String _rupiah(int amount) {
    final digits = amount.toString();
    final result = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      result.write(digits[index]);
      final remaining = digits.length - index - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        result.write('.');
      }
    }

    return 'Rp $result';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OwnerConfigSectionHeader(
              title: 'Kelola layanan',
              subtitle: 'Atur jenis layanan dan harga cuci',
              icon: Icons.local_car_wash_rounded,
              itemCount: _layanan.length,
              isLoading: _isLoading,
              onRefresh: _loadLayanan,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _layanan.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _loadLayanan,
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLayanan,
                      child: _layanan.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 180),
                                Center(
                                  child: Text(
                                    'Belum ada layanan. Tambahkan layanan pertama.',
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 92),
                              itemCount: _layanan.length,
                              itemBuilder: (context, index) {
                                final layanan = _layanan[index];
                                final vehicleType =
                                    layanan['jenis_kendaraan'] as String?;
                                final harga = layanan['harga'] is num
                                    ? (layanan['harga'] as num).toInt()
                                    : int.tryParse(
                                            layanan['harga'].toString(),
                                          ) ??
                                          0;

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
                                      child: Icon(
                                        vehicleType == 'motor'
                                            ? Icons.two_wheeler_rounded
                                            : Icons.directions_car_rounded,
                                        color: const Color(0xFF2369C8),
                                      ),
                                    ),
                                    title: Text(
                                      layanan['nama_layanan'] as String? ??
                                          'Tanpa nama',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            vehicleType == 'motor'
                                                ? 'Motor'
                                                : vehicleType == 'mobil'
                                                ? 'Mobil'
                                                : 'Belum dikategorikan',
                                          ),
                                          Text('• ${_rupiah(harga)}'),
                                          OwnerConfigStatusBadge(
                                            isActive:
                                                layanan['is_active'] == true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () => openDetailedView(
                                      context,
                                      title: 'Detail Layanan',
                                      data: layanan,
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      tooltip: 'Tindakan layanan',
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          _showLayananForm(layanan);
                                        } else if (action == 'delete') {
                                          _deleteLayanan(layanan);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Ubah'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Hapus'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLayananForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah layanan'),
      ),
    );
  }
}
