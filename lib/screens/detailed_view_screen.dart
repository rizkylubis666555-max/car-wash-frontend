import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/transaksi_service.dart';

Future<void> openDetailedView(
  BuildContext context, {
  required String title,
  required Map<String, dynamic> data,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => DetailedViewScreen(title: title, data: data),
    ),
  );
}

class DetailedViewScreen extends StatefulWidget {
  const DetailedViewScreen({
    super.key,
    required this.title,
    required this.data,
  });

  final String title;
  final Map<String, dynamic> data;

  @override
  State<DetailedViewScreen> createState() => _DetailedViewScreenState();
}

class _DetailedViewScreenState extends State<DetailedViewScreen> {
  static const _visibleFields = {
    'name',
    'email',
    'nik',
    'tanggal_kerja',
    'no_whatsapp',
    'role',
    'no_polisi',
    'merk_kendaraan',
    'model_kendaraan',
    'jenis_kendaraan',
    'tipe_pelanggan',
    'nama_layanan',
    'harga',
    'total_harga',
    'status_cucian',
    'status_bayar',
    'metode_bayar',
    'status_operasional',
    'created_at',
    'paid_at',
    'mulai_cuci_at',
    'selesai_cuci_at',
    'cancelled_at',
    'cancel_reason',
    'is_active',
    'wash_threshold',
    'free_washes',
    'periode',
    'total_pendapatan',
    'jumlah_transaksi_lunas',
    'jumlah_kendaraan_selesai',
    'jumlah',
    'tanggal',
    'kendaraan_masuk',
    'pendapatan_diterima',
  };

  static const _visibleSections = {
    'kendaraan',
    'member',
    'layanan',
    'user',
    'operator',
    'kasir',
    'promo',
    'cancelledBy',
  };

  static const _labels = {
    'name': 'Nama',
    'email': 'Email',
    'nik': 'NIK',
    'tanggal_kerja': 'Tanggal kerja',
    'no_whatsapp': 'WhatsApp',
    'role': 'Peran',
    'no_polisi': 'Nomor polisi',
    'merk_kendaraan': 'Merek kendaraan',
    'model_kendaraan': 'Model kendaraan',
    'jenis_kendaraan': 'Jenis kendaraan',
    'tipe_pelanggan': 'Tipe pelanggan',
    'nama_layanan': 'Layanan',
    'harga': 'Harga layanan',
    'total_harga': 'Total pembayaran',
    'status_cucian': 'Status cucian',
    'status_bayar': 'Status pembayaran',
    'metode_bayar': 'Metode pembayaran',
    'status_operasional': 'Status operator',
    'created_at': 'Waktu transaksi',
    'paid_at': 'Waktu pembayaran',
    'mulai_cuci_at': 'Mulai mencuci',
    'selesai_cuci_at': 'Selesai mencuci',
    'cancelled_at': 'Waktu pembatalan',
    'cancel_reason': 'Alasan pembatalan',
    'is_active': 'Status aktif',
    'wash_threshold': 'Target cucian',
    'free_washes': 'Cucian gratis',
    'periode': 'Periode',
    'total_pendapatan': 'Total pendapatan',
    'jumlah_transaksi_lunas': 'Transaksi lunas',
    'jumlah_kendaraan_selesai': 'Kendaraan selesai',
    'jumlah': 'Jumlah',
    'tanggal': 'Tanggal',
    'kendaraan_masuk': 'Kendaraan masuk',
    'pendapatan_diterima': 'Pendapatan diterima',
    'kendaraan': 'Kendaraan',
    'member': 'Profil member',
    'layanan': 'Layanan',
    'user': 'Pelanggan',
    'operator': 'Operator',
    'kasir': 'Kasir',
    'promo': 'Promo',
    'cancelledBy': 'Dibatalkan oleh',
  };

  late Future<Uint8List>? _proofFuture;

  @override
  void initState() {
    super.initState();
    _loadProof();
  }

  void _loadProof() {
    final transactionId = widget.data['id'];
    _proofFuture = widget.data['metode_bayar'] == 'qris' && transactionId is int
        ? TransaksiService().fetchQrisProof(transactionId)
        : null;
  }

  void _retryProof() {
    setState(_loadProof);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE6F1FF), Color(0xFFF9FBFE)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF536B8A).withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF56A5F0), Color(0xFF2369C8)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2369C8,
                          ).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan informasi',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.data.length} data utama',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildValueList(widget.data),
            if (_proofFuture != null) ...[
              const SizedBox(height: 20),
              Text(
                'Bukti pembayaran QRIS',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              FutureBuilder<Uint8List>(
                future: _proofFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bukti tidak dapat dimuat: ${snapshot.error}'),
                        TextButton(
                          onPressed: _retryProof,
                          child: const Text('Coba muat ulang'),
                        ),
                      ],
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(snapshot.data!, fit: BoxFit.contain),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValueList(Map<String, dynamic> values) {
    final isTransaction =
        values.containsKey('status_cucian') ||
        values.containsKey('status_bayar') ||
        values.containsKey('metode_bayar');
    final visibleEntries = values.entries
        .where(
          (entry) =>
              (_visibleFields.contains(entry.key) &&
                  (entry.key != 'created_at' || isTransaction)) ||
              _visibleSections.contains(entry.key) ||
              (entry.value is List &&
                  const {
                    'transaksi',
                    'tugas_aktif',
                    'kendaraan',
                  }.contains(entry.key)),
        )
        .toList();

    if (visibleEntries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Tidak ada informasi utama untuk ditampilkan.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in visibleEntries)
          if (entry.value is Map && _visibleSections.contains(entry.key))
            _buildNestedMap(entry.key, entry.value as Map)
          else if (entry.key == 'operator' && entry.value is List)
            _buildOperatorList(entry.value as List)
          else if (entry.value is List &&
              const {'transaksi', 'tugas_aktif'}.contains(entry.key))
            _buildListSummary(entry.key, entry.value as List)
          else if (entry.key == 'kendaraan' && entry.value is List)
            _buildVehicleList(entry.value as List)
          else
            _buildValueTile(entry.key, entry.value),
      ],
    );
  }

  Widget _buildNestedMap(String label, Map values) {
    final visibleEntries = values.entries
        .where((entry) => _visibleFields.contains(entry.key))
        .toList();
    if (visibleEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _labelFor(label),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            for (final entry in visibleEntries)
              _buildValueTile(
                entry.key.toString(),
                entry.value,
                section: label,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSummary(String key, List values) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                key == 'tugas_aktif'
                    ? '${values.length} tugas aktif tercatat.'
                    : '${values.length} transaksi tercatat. Buka menu Riwayat atau Laporan untuk melihat rinciannya.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleList(List vehicles) {
    if (vehicles.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.directions_car_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Belum ada kendaraan terdaftar.')),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kendaraan terdaftar (${vehicles.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final vehicle in vehicles)
              if (vehicle is Map) _buildVehicleCard(vehicle),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map vehicle) {
    final plate = vehicle['no_polisi'] as String? ?? 'Nomor polisi belum diisi';
    final make = vehicle['merk_kendaraan'] as String? ?? '';
    final model = vehicle['model_kendaraan'] as String? ?? '';
    final vehicleType = switch (vehicle['jenis_kendaraan']) {
      'motor' => 'Motor',
      'mobil' => 'Mobil',
      final String type => type,
      _ => '',
    };
    final vehicleName = [
      make,
      model,
    ].where((value) => value.isNotEmpty).join(' ');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EDF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE5EFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              vehicleType == 'Motor'
                  ? Icons.two_wheeler_rounded
                  : Icons.directions_car_rounded,
              color: const Color(0xFF2369C8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (vehicleName.isNotEmpty || vehicleType.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    [
                      vehicleName,
                      vehicleType,
                    ].where((value) => value.isNotEmpty).join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorList(List operators) {
    final colorScheme = Theme.of(context).colorScheme;
    if (operators.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.engineering_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Belum ada data operator yang dapat ditampilkan.'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Daftar operator',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final operator in operators)
              if (operator is Map) _buildOperatorRow(operator),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorRow(Map operator) {
    final name = operator['name'] as String? ?? 'Operator';
    final isWorking = operator['status_operasional'] == 'bekerja';
    final statusColor = isWorking
        ? const Color(0xFF397AC6)
        : const Color(0xFF2E9D68);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EDF5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.12),
            foregroundColor: statusColor,
            child: Text(
              name.isEmpty ? 'O' : name.characters.first.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isWorking ? 'Bekerja' : 'Menganggur',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueTile(String label, Object? value, {String? section}) {
    final displayLabel = label == 'created_at'
        ? switch (section) {
            'kendaraan' => 'Kendaraan terdaftar',
            'layanan' => 'Layanan dibuat',
            'member' => 'Member terdaftar',
            'user' => 'Akun dibuat',
            'promo' => 'Promo dibuat',
            _ => _labelFor(label),
          }
        : _labelFor(label);
    final displayValue = switch (value) {
      null => '-',
      bool booleanValue => booleanValue ? 'Ya' : 'Tidak',
      String stringValue when _isDateField(label) =>
        _formatDateTime(stringValue) ?? stringValue,
      _ => value.toString(),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8EEF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF536B8A).withValues(alpha: 0.045),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              displayLabel,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SelectableText(
              displayValue,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF172B4D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isDateField(String key) => const {
    'created_at',
    'paid_at',
    'mulai_cuci_at',
    'selesai_cuci_at',
    'cancelled_at',
  }.contains(key);

  String? _formatDateTime(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) {
      return null;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final hasTime = value.contains('T');

    return hasTime
        ? '$day ${months[date.month - 1]} ${date.year}, $hour:$minute'
        : '$day ${months[date.month - 1]} ${date.year}';
  }

  String _humanize(String value) {
    final spaced = value.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match[1]} ${match[2]}',
    );
    return spaced
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _labelFor(String key) => _labels[key] ?? _humanize(key);
}
