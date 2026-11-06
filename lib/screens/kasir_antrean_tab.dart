import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaksi_provider.dart';
import 'detailed_view_screen.dart';
import 'pembayaran_screen.dart';

class KasirAntreanTab extends StatelessWidget {
  const KasirAntreanTab({super.key});

  Future<void> _refreshQueue(BuildContext context) async {
    final provider = context.read<TransaksiProvider>();
    await provider.loadTransaksi(role: 'kasir');
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? 'Antrean berhasil diperbarui.'),
      ),
    );
  }

  Future<void> _cancelTransaction(
    BuildContext context,
    TransaksiProvider provider,
    Map<String, dynamic> transaction,
  ) async {
    final reasonController = TextEditingController();
    String? validationMessage;
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Batalkan transaksi?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Transaksi hanya dapat dibatalkan sebelum mulai dicuci dan sebelum dibayar.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'Alasan pembatalan',
                  border: OutlineInputBorder(),
                ),
              ),
              if (validationMessage != null)
                Text(
                  validationMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Kembali'),
            ),
            FilledButton(
              onPressed: () {
                final value = reasonController.text.trim();
                if (value.length < 5) {
                  setDialogState(() {
                    validationMessage = 'Alasan minimal 5 karakter.';
                  });
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Batalkan transaksi'),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();

    if (reason == null || !context.mounted) {
      return;
    }

    final succeeded = await provider.batalkanTransaksi(
      transaction['id'] as int,
      reason,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded && provider.syncWarningMessage == null
              ? 'Transaksi dibatalkan. Riwayat tetap tersimpan.'
              : succeeded
              ? 'Transaksi dibatalkan, tetapi antrean gagal dimuat ulang: ${provider.syncWarningMessage}'
              : provider.errorMessage ?? 'Pembatalan transaksi gagal.',
        ),
      ),
    );
  }

  Future<void> _assignOperator(
    BuildContext context,
    TransaksiProvider provider,
    Map<String, dynamic> transaction,
  ) async {
    final availableOperators = provider.operatorList
        .where((operator) => operator['status_operasional'] == 'menganggur')
        .toList();
    if (availableOperators.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada operator yang sedang menganggur.'),
        ),
      );
      return;
    }

    final operatorId = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign ke operator'),
        content: SizedBox(
          width: 360,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final operator in provider.operatorList)
                ListTile(
                  title: Text(operator['name'] as String? ?? '-'),
                  subtitle: Text(
                    operator['status_operasional'] as String? ?? 'menganggur',
                  ),
                  enabled: operator['status_operasional'] == 'menganggur',
                  onTap: operator['status_operasional'] == 'menganggur'
                      ? () =>
                            Navigator.pop(dialogContext, operator['id'] as int)
                      : null,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
    if (operatorId == null || !context.mounted) {
      return;
    }

    final succeeded = await provider.assignOperator(
      transaction['id'] as int,
      operatorId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            succeeded && provider.syncWarningMessage == null
                ? 'Kendaraan berhasil ditugaskan kepada operator.'
                : succeeded
                ? 'Penugasan berhasil, tetapi antrean gagal dimuat ulang: ${provider.syncWarningMessage}'
                : provider.errorMessage ?? 'Penugasan operator gagal.',
          ),
        ),
      );
    }
  }

  Future<void> _finishTask(
    BuildContext context,
    TransaksiProvider provider,
    Map<String, dynamic> transaction,
  ) async {
    final succeeded = await provider.finishFromCashier(
      transaction['id'] as int,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            succeeded && provider.syncWarningMessage == null
                ? 'Tugas selesai dari layar kasir.'
                : succeeded
                ? 'Tugas selesai, tetapi antrean gagal dimuat ulang: ${provider.syncWarningMessage}'
                : provider.errorMessage ?? 'Tugas gagal diselesaikan.',
          ),
        ),
      );
    }
  }

  Future<void> _unlockTask(
    BuildContext context,
    TransaksiProvider provider,
    Map<String, dynamic> transaction,
  ) async {
    final reasonController = TextEditingController();
    String? validationMessage;
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Batal / Unlock tugas operator'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tugas akan dilepas dari operator dan dikembalikan ke antrean.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'Alasan Pembatalan',
                  border: OutlineInputBorder(),
                ),
              ),
              if (validationMessage != null)
                Text(
                  validationMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Kembali'),
            ),
            FilledButton(
              onPressed: () {
                final value = reasonController.text.trim();
                if (value.length < 5) {
                  setDialogState(() {
                    validationMessage = 'Alasan Pembatalan minimal 5 karakter.';
                  });
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Lepas tugas'),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();

    if (reason == null || !context.mounted) {
      return;
    }
    final succeeded = await provider.unlockOperatorTask(
      transaction['id'] as int,
      reason,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            succeeded && provider.syncWarningMessage == null
                ? 'Tugas dikembalikan ke antrean.'
                : succeeded
                ? 'Tugas dilepas, tetapi antrean gagal dimuat ulang: ${provider.syncWarningMessage}'
                : provider.errorMessage ?? 'Tugas gagal dilepas.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF56A5F0), Color(0xFF2369C8)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antrean kendaraan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Kelola proses cuci secara langsung',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer<TransaksiProvider>(
                    builder: (context, provider, child) =>
                        IconButton.filledTonal(
                          tooltip: 'Muat ulang antrean',
                          onPressed: provider.isLoading
                              ? null
                              : () => _refreshQueue(context),
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                  ),
                ],
              ),
            ),
            Consumer<TransaksiProvider>(
              builder: (context, provider, child) {
                final activeQueue = provider.transaksiList.where(
                  (transaction) =>
                      transaction['status_bayar'] == 'belum' &&
                      transaction['cancelled_at'] == null,
                );
                final waitingCount = activeQueue
                    .where(
                      (transaction) =>
                          transaction['status_cucian'] == 'menunggu',
                    )
                    .length;
                final washingCount = activeQueue
                    .where(
                      (transaction) => transaction['status_cucian'] == 'dicuci',
                    )
                    .length;
                final completedCount = activeQueue
                    .where(
                      (transaction) =>
                          transaction['status_cucian'] == 'selesai',
                    )
                    .length;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        height: 58,
                        child: TabBar(
                          isScrollable: false,
                          tabAlignment: TabAlignment.fill,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorPadding: const EdgeInsets.all(4),
                          dividerHeight: 0,
                          labelPadding: EdgeInsets.zero,
                          tabs: [
                            _buildQueueTab(context, 'Menunggu', waitingCount),
                            _buildQueueTab(context, 'Dicuci', washingCount),
                            _buildQueueTab(context, 'Selesai', completedCount),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
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
                        padding: const EdgeInsets.all(20),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE58937,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.cloud_off_rounded,
                                    color: Color(0xFFE58937),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Antrean belum dapat dimuat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  provider.errorMessage!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                FilledButton.icon(
                                  onPressed: provider.isLoading
                                      ? null
                                      : () => provider.loadTransaksi(
                                          role: 'kasir',
                                        ),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Coba muat ulang'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // Filter data berdasarkan status cuci dan belum lunas
                  final antreanAktif = provider.transaksiList
                      .where(
                        (t) =>
                            t['status_bayar'] == 'belum' &&
                            t['cancelled_at'] == null,
                      )
                      .toList();
                  final listMenunggu = antreanAktif
                      .where((t) => t['status_cucian'] == 'menunggu')
                      .toList();
                  final listDicuci = antreanAktif
                      .where((t) => t['status_cucian'] == 'dicuci')
                      .toList();
                  final listSelesai = antreanAktif
                      .where((t) => t['status_cucian'] == 'selesai')
                      .toList();

                  return TabBarView(
                    children: [
                      _buildList(context, listMenunggu),
                      _buildList(context, listDicuci),
                      _buildList(context, listSelesai, isSelesai: true),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Tab _buildQueueTab(BuildContext context, String label, int count) {
    return Tab(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(minWidth: 22),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<dynamic> data, {
    bool isSelesai = false,
  }) {
    if (data.isEmpty) {
      return const Center(child: Text('Tidak ada kendaraan di status ini.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final trx = data[index];
        final noPolisi = trx['kendaraan']?['no_polisi'] ?? '-';
        final merk = trx['kendaraan']?['merk_kendaraan'] ?? '-';
        final jenisKendaraan = trx['kendaraan']?['jenis_kendaraan'];
        final namaMember =
            trx['user']?['name'] ?? trx['kendaraan']?['user']?['name'];
        final namaOperator = trx['operator']?['name'];
        final layanan =
            trx['nama_layanan'] ?? trx['layanan']?['nama_layanan'] ?? '-';
        final status = trx['status_cucian'];
        final statusColor = status == 'selesai'
            ? const Color(0xFF2E9D68)
            : status == 'dicuci'
            ? const Color(0xFF397AC6)
            : const Color(0xFFE58937);

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(
              jenisKendaraan == 'motor'
                  ? Icons.two_wheeler
                  : Icons.directions_car,
              color: Colors.blueGrey,
            ),
            title: Text(
              noPolisi,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (jenisKendaraan is String && jenisKendaraan.isNotEmpty) ...[
                  Text(
                    jenisKendaraan == 'motor' ? 'Motor' : 'Mobil',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                ],
                if (namaMember is String && namaMember.isNotEmpty) ...[
                  Text(
                    'Member: $namaMember',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                ],
                if (namaOperator is String && namaOperator.isNotEmpty) ...[
                  Text(
                    'Dicuci oleh: $namaOperator',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(merk, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(layanan, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'Tindakan antrean',
              onSelected: (action) {
                final provider = context.read<TransaksiProvider>();
                switch (action) {
                  case 'assign':
                    _assignOperator(context, provider, trx);
                    break;
                  case 'cancel':
                    _cancelTransaction(context, provider, trx);
                    break;
                  case 'finish':
                    _finishTask(context, provider, trx);
                    break;
                  case 'unlock':
                    _unlockTask(context, provider, trx);
                    break;
                  case 'pay':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PembayaranScreen(transaksi: trx),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                if (status == 'menunggu') ...[
                  const PopupMenuItem(
                    value: 'assign',
                    child: Text('Assign operator'),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text('Batalkan transaksi'),
                  ),
                ],
                if (status == 'dicuci') ...[
                  const PopupMenuItem(
                    value: 'finish',
                    child: Text('Selesaikan tugas'),
                  ),
                  const PopupMenuItem(
                    value: 'unlock',
                    child: Text('Batal / Unlock tugas operator'),
                  ),
                ],
                if (isSelesai)
                  const PopupMenuItem(
                    value: 'pay',
                    child: Text('Proses pembayaran'),
                  ),
              ],
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.more_vert),
                ],
              ),
            ),
            onTap: () => openDetailedView(
              context,
              title: 'Detail Antrean $noPolisi',
              data: Map<String, dynamic>.from(trx),
            ),
          ),
        );
      },
    );
  }
}
