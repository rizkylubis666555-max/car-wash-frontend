import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/transaksi_provider.dart';
import 'detailed_view_screen.dart';

class OperatorHomeTab extends StatelessWidget {
  const OperatorHomeTab({
    super.key,
    required this.onRefresh,
  });

  final Future<void> Function() onRefresh;

  bool _isToday(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    final now = DateTime.now();

    return date != null &&
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final operatorId = context.watch<AuthProvider>().user?['id']?.toString();

    return Scaffold(
      body: Consumer<TransaksiProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.transaksiList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.transaksiList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(provider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: onRefresh,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final transactions = provider.transaksiList
              .where((transaction) => transaction['cancelled_at'] == null)
              .toList();
          final waiting = transactions
              .where(
                (transaction) => transaction['status_cucian'] == 'menunggu',
              )
              .where((transaction) => transaction['operator_id'] == null)
              .toList();
          final washing = transactions
              .where((transaction) => transaction['status_cucian'] == 'dicuci')
              .where(
                (transaction) =>
                    transaction['operator_id']?.toString() == operatorId,
              )
              .toList();
          final completedToday = transactions
              .where((transaction) => transaction['status_cucian'] == 'selesai')
              .where(
                (transaction) =>
                    transaction['operator_id']?.toString() == operatorId &&
                    _isToday(transaction['selesai_cuci_at']),
              )
              .toList();

          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        context
                                .read<AuthProvider>()
                                .user?['name']
                                ?.toString()
                                .characters
                                .firstOrNull ??
                            'O',
                      ),
                    ),
                    title: Text(
                      'Halo, ${context.read<AuthProvider>().user?['name'] ?? 'Operator'}',
                    ),
                    subtitle: Text(
                      washing.isEmpty
                          ? 'Status: Menganggur'
                          : 'Status: Bekerja • ${washing.first['kendaraan']?['no_polisi'] ?? '-'}',
                    ),
                    onTap: () => openDetailedView(
                      context,
                      title: 'Ringkasan Operator',
                      data: {
                        'operator': context.read<AuthProvider>().user ?? {},
                        'tugas_aktif': washing,
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MetricBox(
                      label: 'Menunggu',
                      count: waiting.length,
                      onTap: () => openDetailedView(
                        context,
                        title: 'Antrean Menunggu',
                        data: {'jumlah': waiting.length, 'transaksi': waiting},
                      ),
                    ),
                    _MetricBox(
                      label: 'Dicuci Saya',
                      count: washing.length,
                      onTap: () => openDetailedView(
                        context,
                        title: 'Tugas Sedang Dicuci',
                        data: {'jumlah': washing.length, 'transaksi': washing},
                      ),
                    ),
                    _MetricBox(
                      label: 'Selesai Hari Ini',
                      count: completedToday.length,
                      onTap: () => openDetailedView(
                        context,
                        title: 'Tugas Selesai Hari Ini',
                        data: {
                          'jumlah': completedToday.length,
                          'transaksi': completedToday,
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (washing.isNotEmpty)
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => openDetailedView(
                        context,
                        title: 'Tugas Aktif Operator',
                        data: {
                          'jumlah_tugas_aktif': washing.length,
                          'transaksi': washing,
                        },
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Anda memegang satu tugas aktif. Selesaikan tugas tersebut sebelum mengambil antrean lain.',
                        ),
                      ),
                    ),
                  ),
                if (provider.errorMessage != null ||
                    provider.syncWarningMessage != null)
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sync_problem,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.errorMessage != null
                                  ? 'Sinkronisasi tertunda: ${provider.errorMessage}'
                                  : 'Tugas berhasil diproses, tetapi daftar belum diperbarui: ${provider.syncWarningMessage}',
                              style: TextStyle(color: Colors.amber.shade900),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Coba sinkronkan lagi',
                            onPressed: onRefresh,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (label) {
      'Menunggu' => (Icons.hourglass_bottom_rounded, const Color(0xFFE58937)),
      'Dicuci Saya' => (Icons.local_car_wash_rounded, const Color(0xFF397AC6)),
      _ => (Icons.check_circle_rounded, const Color(0xFF2E9D68)),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.72), color],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.22),
                          blurRadius: 9,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 21),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF74849A),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$count unit',
                style: const TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
