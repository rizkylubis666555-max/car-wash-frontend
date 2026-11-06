import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaksi_provider.dart';
import 'detailed_view_screen.dart';

class OwnerLaporanTab extends StatefulWidget {
  const OwnerLaporanTab({super.key});

  @override
  State<OwnerLaporanTab> createState() => _OwnerLaporanTabState();
}

class _OwnerLaporanTabState extends State<OwnerLaporanTab> {
  String _searchQuery = '';
  String _statusFilter = 'semua';
  DateTimeRange? _dateRange;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange:
          _dateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month, now.day),
          ),
      helpText: 'Pilih periode laporan',
      cancelText: 'Batal',
      confirmText: 'Pakai periode',
    );
    if (picked != null && mounted) setState(() => _dateRange = picked);
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _rupiah(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }

  int _amount(Map<String, dynamic> transaction) {
    final raw = transaction['total_harga'] ?? 0;
    return raw is num ? raw.toInt() : 0;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF328FEA), Color(0xFF2058B7)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2369C8).withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.analytics_rounded, color: Colors.white, size: 30),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laporan operasional',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Pantau pendapatan, antrean, dan kinerja',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.trim().toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Cari nomor polisi...',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'semua', label: Text('Semua')),
                          ButtonSegment(
                            value: 'menunggu',
                            label: Text('Menunggu'),
                          ),
                          ButtonSegment(value: 'dicuci', label: Text('Dicuci')),
                          ButtonSegment(
                            value: 'selesai',
                            label: Text('Selesai'),
                          ),
                        ],
                        selected: {_statusFilter},
                        onSelectionChanged: (selection) {
                          setState(() => _statusFilter = selection.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dateRange == null
                                ? 'Semua tanggal'
                                : '${_dateLabel(_dateRange!.start)} – ${_dateLabel(_dateRange!.end)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: const Text('Periode'),
                        ),
                        if (_dateRange != null)
                          IconButton(
                            onPressed: () => setState(() => _dateRange = null),
                            tooltip: 'Hapus periode',
                            icon: const Icon(Icons.close_rounded),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<TransaksiProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.errorMessage != null &&
                    provider.transaksiList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () =>
                                provider.loadTransaksi(role: 'owner'),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filtered =
                    provider.transaksiList.where((item) {
                      final vehicle =
                          item['kendaraan'] as Map<String, dynamic>? ?? {};
                      final plate = (vehicle['no_polisi'] as String? ?? '')
                          .toLowerCase();
                      final washStatus =
                          item['status_cucian'] as String? ?? 'menunggu';
                      final reportDate = DateTime.tryParse(
                        item['cancelled_at'] as String? ??
                            (item['status_bayar'] == 'lunas'
                                ? item['paid_at'] as String? ?? ''
                                : item['created_at'] as String? ?? ''),
                      )?.toLocal();
                      final matchesSearch = plate.contains(_searchQuery);
                      final matchesStatus =
                          _statusFilter == 'semua' ||
                          (item['cancelled_at'] == null &&
                              washStatus == _statusFilter);
                      final matchesDate =
                          _dateRange == null ||
                          (reportDate != null &&
                              !reportDate.isBefore(
                                DateTime(
                                  _dateRange!.start.year,
                                  _dateRange!.start.month,
                                  _dateRange!.start.day,
                                ),
                              ) &&
                              reportDate.isBefore(
                                DateTime(
                                  _dateRange!.end.year,
                                  _dateRange!.end.month,
                                  _dateRange!.end.day + 1,
                                ),
                              ));
                      return matchesSearch && matchesStatus && matchesDate;
                    }).toList()..sort(
                      (a, b) => (b['created_at'] as String? ?? '').compareTo(
                        a['created_at'] as String? ?? '',
                      ),
                    );

                final paid = filtered
                    .where(
                      (item) =>
                          item['status_bayar'] == 'lunas' &&
                          item['cancelled_at'] == null,
                    )
                    .toList();
                final revenue = paid.fold<int>(
                  0,
                  (sum, item) => sum + _amount(item),
                );
                final missingPriceCount = paid
                    .where((item) => item['total_harga'] == null)
                    .length;
                final operatorNames = <int, String>{};
                final completedByOperator = <int, int>{};
                for (final transaction in filtered.where(
                  (item) =>
                      item['status_cucian'] == 'selesai' &&
                      item['cancelled_at'] == null,
                )) {
                  final operator = transaction['operator'];
                  if (operator is Map<String, dynamic>) {
                    final operatorId = operator['id'];
                    if (operatorId is! int) {
                      continue;
                    }
                    operatorNames[operatorId] =
                        operator['name'] as String? ?? 'Operator';
                    completedByOperator.update(
                      operatorId,
                      (count) => count + 1,
                      ifAbsent: () => 1,
                    );
                  }
                }

                final operatorScores = completedByOperator.entries.toList()
                  ..sort(
                    (first, second) => second.value.compareTo(first.value),
                  );
                final periodLabel = _dateRange == null
                    ? 'Semua tanggal'
                    : '${_dateLabel(_dateRange!.start)} – ${_dateLabel(_dateRange!.end)}';

                return RefreshIndicator(
                  onRefresh: () => provider.loadTransaksi(role: 'owner'),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => openDetailedView(
                            context,
                            title: 'Rincian Pendapatan',
                            data: {
                              'periode': periodLabel,
                              'total_pendapatan': revenue,
                              'jumlah_transaksi_lunas': paid.length,
                              'transaksi': paid,
                            },
                          ),
                          child: Ink(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF328FEA), Color(0xFF2058B7)],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Pendapatan diterima',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          periodLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.open_in_new_rounded,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _rupiah(revenue),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 29,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      _ReportMiniStat(
                                        label: 'Transaksi lunas',
                                        value: '${paid.length}',
                                      ),
                                      const SizedBox(width: 10),
                                      _ReportMiniStat(
                                        label: 'Sesuai filter',
                                        value: '${filtered.length}',
                                      ),
                                    ],
                                  ),
                                  if (_dateRange != null &&
                                      provider.transaksiList.any(
                                        (item) =>
                                            item['status_bayar'] == 'lunas' &&
                                            item['paid_at'] == null,
                                      )) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Transaksi lunas lama tanpa waktu pembayaran tidak dapat dimasukkan ke periode ini.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  if (missingPriceCount > 0) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '$missingPriceCount transaksi lunas tanpa harga tersimpan tidak dihitung.',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kendaraan selesai per operator',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              if (operatorScores.isEmpty)
                                const Text(
                                  'Belum ada cucian selesai dengan operator tercatat.',
                                )
                              else
                                ...operatorScores.map(
                                  (score) => InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => openDetailedView(
                                      context,
                                      title:
                                          'Rincian Operator ${operatorNames[score.key]}',
                                      data: {
                                        'operator_id': score.key,
                                        'operator': operatorNames[score.key],
                                        'jumlah_kendaraan_selesai': score.value,
                                        'transaksi': filtered.where((
                                          transaction,
                                        ) {
                                          final operator =
                                              transaction['operator'];
                                          return operator
                                                  is Map<String, dynamic> &&
                                              operator['id'] == score.key;
                                        }).toList(),
                                      },
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${operatorNames[score.key]} (ID ${score.key})',
                                            ),
                                          ),
                                          Text('${score.value} kendaraan'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 36),
                          child: Center(
                            child: Text('Tidak ada transaksi yang cocok.'),
                          ),
                        )
                      else
                        ...filtered.map((transaction) {
                          final vehicle =
                              transaction['kendaraan']
                                  as Map<String, dynamic>? ??
                              {};
                          final service =
                              transaction['layanan'] as Map<String, dynamic>? ??
                              {};
                          final plate = vehicle['no_polisi'] as String? ?? '-';
                          final brand =
                              vehicle['merk_kendaraan'] as String? ?? '-';
                          final vehicleType =
                              vehicle['jenis_kendaraan'] as String?;
                          final member = transaction['user'];
                          final operator = transaction['operator'];
                          final memberName = member is Map<String, dynamic>
                              ? member['name'] as String?
                              : null;
                          final operatorName = operator is Map<String, dynamic>
                              ? operator['name'] as String?
                              : null;
                          final serviceName =
                              transaction['nama_layanan'] as String? ??
                              service['nama_layanan'] as String? ??
                              '-';
                          final washStatus =
                              transaction['status_cucian'] as String? ??
                              'menunggu';
                          final paymentStatus =
                              transaction['status_bayar'] as String? ?? 'belum';
                          final isCancelled =
                              transaction['cancelled_at'] != null;
                          final statusColor = isCancelled
                              ? Colors.red
                              : switch (washStatus) {
                                  'selesai' => Colors.green,
                                  'dicuci' => Colors.blue,
                                  _ => Colors.orange,
                                };
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                plate,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      [
                                        if (vehicleType != null)
                                          vehicleType == 'motor'
                                              ? 'Motor'
                                              : 'Mobil',
                                        brand,
                                        serviceName,
                                      ].join(' • '),
                                    ),
                                    if (memberName != null)
                                      Text('Member: $memberName'),
                                    if (operatorName != null)
                                      Text('Dicuci oleh: $operatorName'),
                                    if (isCancelled) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Alasan pembatalan: ${transaction['cancel_reason'] ?? 'Tidak dicatat'}',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 5),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Chip(
                                          label: Text(
                                            isCancelled
                                                ? 'DIBATALKAN'
                                                : switch (washStatus) {
                                                    'dicuci' => 'SEDANG DICUCI',
                                                    _ =>
                                                      washStatus.toUpperCase(),
                                                  },
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: statusColor
                                              .withValues(alpha: .12),
                                          side: BorderSide.none,
                                          labelStyle: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            paymentStatus.toUpperCase(),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          side: BorderSide.none,
                                          backgroundColor:
                                              paymentStatus == 'lunas'
                                              ? Colors.green.withValues(
                                                  alpha: .10,
                                                )
                                              : Colors.grey.withValues(
                                                  alpha: .12,
                                                ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Text(
                                transaction['total_harga'] == null
                                    ? 'Harga tidak tercatat'
                                    : _rupiah(_amount(transaction)),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              isThreeLine: true,
                              onTap: () => openDetailedView(
                                context,
                                title: 'Detail Transaksi $plate',
                                data: Map<String, dynamic>.from(transaction),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMiniStat extends StatelessWidget {
  const _ReportMiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
