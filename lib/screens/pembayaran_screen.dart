import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaksi_provider.dart';
import 'camera_capture_screen.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key, required this.transaksi});

  final Map<String, dynamic> transaksi;

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  String _metodeBayar = 'cash';
  final TextEditingController _uangDiterimaController = TextEditingController();
  Uint8List? _qrisProofBytes;

  @override
  void dispose() {
    _uangDiterimaController.dispose();
    super.dispose();
  }

  Future<void> _eksekusiBayar() async {
    final rawAmount = widget.transaksi['total_harga'] ?? 0;
    final harga = rawAmount is num ? rawAmount.toInt() : 0;
    final uangDiterima = int.tryParse(_uangDiterimaController.text) ?? 0;

    if (harga <= 0) {
      _showMessage(
        'Harga transaksi belum tercatat. Hubungi owner sebelum menerima pembayaran.',
      );
      return;
    }
    if (_metodeBayar == 'cash' && uangDiterima < harga) {
      _showMessage('Uang diterima kurang dari total tagihan.');
      return;
    }
    if (_metodeBayar == 'qris' && _qrisProofBytes == null) {
      _showMessage('Ambil foto bukti QRIS dengan kamera sebelum konfirmasi.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final content = _metodeBayar == 'cash'
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Total tagihan', 'Rp $harga'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Uang diterima', 'Rp $uangDiterima'),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Kembalian',
                    'Rp ${uangDiterima - harga}',
                    isBold: true,
                  ),
                ],
              )
            : const Text(
                'Pastikan pembayaran QRIS sudah diterima sebelum '
                'mengonfirmasi. Koneksi ke penyedia QRIS belum tersedia '
                'pada versi demo ini.',
              );

        return AlertDialog(
          title: const Text('Konfirmasi pembayaran'),
          content: content,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Kembali'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Konfirmasi'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<TransaksiProvider>();
    final success = await provider.prosesPembayaran(
      widget.transaksi['id'] as int,
      _metodeBayar,
      buktiQris: _qrisProofBytes,
    );
    if (!mounted) {
      return;
    }

    if (success) {
      final message = provider.syncWarningMessage == null
          ? 'Pembayaran berhasil dikonfirmasi.'
          : 'Pembayaran berhasil, tetapi antrean gagal dimuat ulang: ${provider.syncWarningMessage}';
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    } else {
      _showMessage(provider.errorMessage ?? 'Pembayaran gagal diproses.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaksi;
    final vehicle = transaction['kendaraan'] as Map<String, dynamic>? ?? {};
    final service = transaction['layanan'] as Map<String, dynamic>? ?? {};
    final member = transaction['user'];
    final operator = transaction['operator'];
    final rawAmount = transaction['total_harga'] ?? 0;
    final amount = rawAmount is num ? rawAmount.toInt() : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Detail transaksi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (amount <= 0) ...[
                const SizedBox(height: 12),
                const Text(
                  'Harga transaksi belum tercatat. Hubungi owner sebelum menerima pembayaran.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Nomor polisi',
                        vehicle['no_polisi'] as String? ?? '-',
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Jenis kendaraan',
                        switch (vehicle['jenis_kendaraan']) {
                          'motor' => 'Motor',
                          'mobil' => 'Mobil',
                          _ => '-',
                        },
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Kendaraan',
                        vehicle['merk_kendaraan'] as String? ?? '-',
                      ),
                      const Divider(height: 24),
                      if (member is Map<String, dynamic>) ...[
                        _buildDetailRow(
                          'Member',
                          member['name'] as String? ?? '-',
                        ),
                        const Divider(height: 24),
                      ],
                      if (operator is Map<String, dynamic>) ...[
                        _buildDetailRow(
                          'Dicuci oleh',
                          operator['name'] as String? ?? '-',
                        ),
                        const Divider(height: 24),
                      ],
                      _buildDetailRow(
                        'Layanan',
                        transaction['nama_layanan'] as String? ??
                            service['nama_layanan'] as String? ??
                            '-',
                      ),
                      const Divider(height: 24),
                      _buildDetailRow('Total', 'Rp $amount', isBold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Metode pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              RadioGroup<String>(
                groupValue: _metodeBayar,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _metodeBayar = value;
                      if (value != 'qris') {
                        _qrisProofBytes = null;
                      }
                    });
                  }
                },
                child: Column(
                  children: const [
                    RadioListTile<String>(
                      value: 'cash',
                      title: Text('Tunai'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      value: 'qris',
                      title: Text('QRIS (foto bukti wajib)'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              if (_metodeBayar == 'cash') ...[
                TextField(
                  controller: _uangDiterimaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Uang diterima (Rp)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                const Text(
                  'Foto bukti pembayaran harus diambil langsung dari kamera.',
                ),
                const SizedBox(height: 12),
                if (_qrisProofBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _qrisProofBytes!,
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final captured = await Navigator.of(context)
                        .push<Uint8List>(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => const CameraCaptureScreen(
                              title: 'Foto bukti pembayaran QRIS',
                            ),
                          ),
                        );
                    if (captured != null && mounted) {
                      setState(() {
                        _qrisProofBytes = captured;
                      });
                    }
                  },
                  icon: Icon(
                    _qrisProofBytes == null ? Icons.camera_alt : Icons.refresh,
                  ),
                  label: Text(
                    _qrisProofBytes == null
                        ? 'Ambil foto bukti QRIS'
                        : 'Retake / Ambil Ulang Foto',
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Consumer<TransaksiProvider>(
                builder: (context, provider, child) {
                  return FilledButton(
                    onPressed: provider.isLoading || amount <= 0
                        ? null
                        : _eksekusiBayar,
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Konfirmasi pembayaran'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
