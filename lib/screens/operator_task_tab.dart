import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/transaksi_provider.dart';
import '../widgets/slide_to_finish_control.dart';
import 'detailed_view_screen.dart';

enum OperatorTaskMode { waiting, washing, completed }

class OperatorTaskTab extends StatelessWidget {
  const OperatorTaskTab({super.key, required this.mode});

  final OperatorTaskMode mode;

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
                      onPressed: () => provider.loadTransaksi(role: 'operator'),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allActive = provider.transaksiList
              .where((transaction) => transaction['cancelled_at'] == null)
              .toList();
          final activeJobs = allActive
              .where((transaction) => transaction['status_cucian'] == 'dicuci')
              .where(
                (transaction) =>
                    transaction['operator_id']?.toString() == operatorId,
              )
              .toList();
          final tasks = switch (mode) {
            OperatorTaskMode.waiting =>
              allActive
                  .where(
                    (transaction) => transaction['status_cucian'] == 'menunggu',
                  )
                  .where((transaction) => transaction['operator_id'] == null)
                  .toList(),
            OperatorTaskMode.washing => activeJobs,
            OperatorTaskMode.completed =>
              allActive
                  .where(
                    (transaction) => transaction['status_cucian'] == 'selesai',
                  )
                  .where(
                    (transaction) =>
                        transaction['operator_id']?.toString() == operatorId &&
                        _isToday(transaction['selesai_cuci_at']),
                  )
                  .toList(),
          };

          if (tasks.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadTransaksi(role: 'operator'),
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: Center(
                      child: Text(
                        mode == OperatorTaskMode.waiting
                            ? 'Belum ada kendaraan di antrean menunggu.'
                            : mode == OperatorTaskMode.washing
                            ? 'Anda tidak memiliki tugas aktif.'
                            : 'Belum ada tugas selesai hari ini.',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (mode == OperatorTaskMode.washing) {
            return _buildWashingTask(context, provider, tasks.first);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadTransaksi(role: 'operator'),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final transaction = tasks[index];
                final vehicle =
                    transaction['kendaraan'] as Map<String, dynamic>? ?? {};
                final plate = vehicle['no_polisi'] as String? ?? '-';
                final isWaiting = mode == OperatorTaskMode.waiting;
                final statusColor = isWaiting
                    ? const Color(0xFFE58937)
                    : const Color(0xFF2E9D68);
                final statusLabel = isWaiting ? 'MENUNGGU' : 'SELESAI';
                final card = Card(
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            plate,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      [
                        transaction['nama_layanan'] ??
                            transaction['layanan']?['nama_layanan'] ??
                            '-',
                        [vehicle['merk_kendaraan'], vehicle['model_kendaraan']]
                            .where((value) => value != null && value != '')
                            .join(' '),
                      ].where((item) => item.toString().isNotEmpty).join(' • '),
                    ),
                    trailing: isWaiting
                        ? FilledButton(
                            onPressed:
                                activeJobs.isNotEmpty || provider.isLoading
                                ? null
                                : () =>
                                      _takeTask(context, provider, transaction),
                            child: Text(
                              activeJobs.isNotEmpty
                                  ? 'Selesaikan tugas aktif'
                                  : 'Ambil',
                            ),
                          )
                        : mode == OperatorTaskMode.washing
                        ? const Icon(Icons.swipe)
                        : const Icon(Icons.check_circle, color: Colors.green),
                    onTap: () => openDetailedView(
                      context,
                      title: 'Detail Tugas $plate',
                      data: Map<String, dynamic>.from(transaction),
                    ),
                  ),
                );

                return card;
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWashingTask(
    BuildContext context,
    TransaksiProvider provider,
    Map<String, dynamic> transaction,
  ) {
    final vehicle = transaction['kendaraan'] as Map<String, dynamic>? ?? {};
    final member =
        transaction['user'] as Map<String, dynamic>? ??
        vehicle['user'] as Map<String, dynamic>? ??
        {};
    final service = transaction['layanan'] as Map<String, dynamic>? ?? {};
    final plate = vehicle['no_polisi'] as String? ?? '-';
    final vehicleName = [
      vehicle['merk_kendaraan'],
      vehicle['model_kendaraan'],
    ].where((value) => value is String && value.isNotEmpty).join(' ');

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.loadTransaksi(role: 'operator'),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              children: [
                Text(
                  'Kendaraan yang sedang dicuci',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_car_filled_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                plate,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF397AC6,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF397AC6,
                                  ).withValues(alpha: 0.24),
                                ),
                              ),
                              child: const Text(
                                'DICUCI',
                                style: TextStyle(
                                  color: Color(0xFF397AC6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (vehicleName.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            vehicleName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                        const Divider(height: 28),
                        _taskDetail(
                          context,
                          'Jenis kendaraan',
                          _labelForVehicleType(vehicle['jenis_kendaraan']),
                          Icons.category_outlined,
                        ),
                        _taskDetail(
                          context,
                          'Pelanggan',
                          member['name'] as String? ?? 'Reguler',
                          Icons.person_outline,
                        ),
                        _taskDetail(
                          context,
                          'Layanan',
                          transaction['nama_layanan'] as String? ??
                              service['nama_layanan'] as String? ??
                              '-',
                          Icons.local_car_wash_outlined,
                        ),
                        _taskDetail(
                          context,
                          'Mulai dicuci',
                          _formatDateTime(transaction['mulai_cuci_at']),
                          Icons.schedule_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Periksa kendaraan dan layanan sebelum menyelesaikan tugas.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SlideToFinishControl(
              enabled: !provider.isLoading,
              onComplete: () => _finishTask(context, provider, transaction),
            ),
          ),
        ),
      ],
    );
  }

  Widget _taskDetail(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _labelForVehicleType(dynamic type) => switch (type) {
    'motor' => 'Motor',
    'mobil' => 'Mobil',
    _ => '-',
  };

  String _formatDateTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) {
      return '-';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
  }

  Future<bool> _finishTask(
    BuildContext context,
    TransaksiProvider provider,
    Map<String, dynamic> transaction,
  ) async {
    final succeeded = await provider.ubahStatusCuci(
      transaction['id'] as int,
      'selesai',
    );
    if (!context.mounted) {
      return succeeded;
    }

    final message = succeeded
        ? provider.syncWarningMessage == null
              ? 'Tugas berhasil diselesaikan.'
              : 'Tugas selesai, tetapi antrean gagal dimuat ulang: ${provider.syncWarningMessage}'
        : provider.errorMessage ?? 'Tugas gagal diselesaikan.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    return succeeded;
  }

  Future<void> _takeTask(
    BuildContext context,
    TransaksiProvider provider,
    Map<String, dynamic> transaction,
  ) async {
    final succeeded = await provider.ubahStatusCuci(
      transaction['id'] as int,
      'dicuci',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            succeeded
                ? provider.syncWarningMessage == null
                      ? 'Tugas berhasil diambil.'
                      : 'Tugas berhasil diambil, tetapi antrean gagal dimuat ulang: ${provider.syncWarningMessage}'
                : provider.errorMessage ?? 'Tugas tidak tersedia.',
          ),
        ),
      );
    }
  }
}
