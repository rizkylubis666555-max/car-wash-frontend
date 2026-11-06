import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaksi_provider.dart';
import 'main_scaffold.dart';
import 'input_kendaraan_screen.dart';
import 'kasir_antrean_tab.dart';
import 'kasir_riwayat_tab.dart'; // 1. Tambahkan import tab riwayat
import 'kasir_profil_tab.dart'; // 2. Tambahkan import tab profil
import 'detailed_view_screen.dart';

class KasirDashboard extends StatefulWidget {
  const KasirDashboard({super.key});

  @override
  State<KasirDashboard> createState() => _KasirDashboardState();
}

class _KasirDashboardState extends State<KasirDashboard> {
  Timer? _queueSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransaksiProvider>(
        context,
        listen: false,
      ).loadTransaksi(role: 'kasir');
    });
    _queueSyncTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => context.read<TransaksiProvider>().refreshTransaksiSilently(),
    );
  }

  @override
  void dispose() {
    _queueSyncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MainScaffold bertindak sebagai kerangka bawah (Bottom Navigation)
    return MainScaffold(
      role: 'kasir',
      pages: [
        _buildHomeTab(), // Index 0: Beranda
        const KasirAntreanTab(), // Index 1: Antrean
        const KasirRiwayatTab(), // Index 2: Riwayat
        const KasirProfilTab(), // Index 3: Profil
      ],
      navItems: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car_outlined),
          activeIcon: Icon(Icons.directions_car),
          label: 'Antrean',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }

  // Merender antarmuka Beranda sesuai Mockup Kasir Halaman 1
  Widget _buildHomeTab() {
    return Consumer<TransaksiProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
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
                    onPressed: () => provider.loadTransaksi(role: 'kasir'),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final todayTransactions = provider.transaksiList
            .where((transaction) => transaction['cancelled_at'] == null)
            .where(_isToday)
            .toList();
        final kendaraanMasuk = todayTransactions.length;
        final selesaiDicuci = todayTransactions
            .where((transaction) => transaction['status_cucian'] == 'selesai')
            .where((transaction) {
              final completedAt = DateTime.tryParse(
                transaction['selesai_cuci_at'] as String? ?? '',
              )?.toLocal();

              return completedAt != null &&
                  completedAt.year == DateTime.now().year &&
                  completedAt.month == DateTime.now().month &&
                  completedAt.day == DateTime.now().day;
            })
            .length;
        final totalTransaksi = provider.transaksiList
            .where((transaction) => transaction['cancelled_at'] == null)
            .where((transaction) => transaction['status_bayar'] == 'lunas')
            .where((transaction) {
              final paidAt = DateTime.tryParse(
                transaction['paid_at'] as String? ?? '',
              )?.toLocal();

              return paidAt != null &&
                  paidAt.year == DateTime.now().year &&
                  paidAt.month == DateTime.now().month &&
                  paidAt.day == DateTime.now().day;
            })
            .fold<int>(0, (sum, transaction) => sum + _amount(transaction));

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Beranda Kasir',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _CashierActionCard(
                  title: 'Input Kendaraan',
                  subtitle: 'Tambah kendaraan baru ke antrean',
                  icon: Icons.directions_car_rounded,
                  colors: const [Color(0xFF47A6F2), Color(0xFF2369C8)],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InputKendaraanScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _CashierActionCard(
                  title: 'Antrean Kendaraan',
                  subtitle: 'Lihat dan kelola antrean aktif',
                  icon: Icons.receipt_long_rounded,
                  colors: const [Color(0xFF48B69A), Color(0xFF23876F)],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Antrean Kendaraan')),
                        body: const KasirAntreanTab(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Panel Ringkasan Hari Ini
                const Text(
                  'Ringkasan Hari Ini',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => openDetailedView(
                    context,
                    title: 'Ringkasan Operasi Hari Ini',
                    data: {
                      'kendaraan_masuk': kendaraanMasuk,
                      'selesai_dicuci': selesaiDicuci,
                      'pendapatan_diterima': totalTransaksi,
                      'transaksi': todayTransactions,
                    },
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          'Kendaraan Masuk',
                          kendaraanMasuk.toString(),
                        ),
                        const Divider(height: 32),
                        _buildSummaryRow(
                          'Selesai Dicuci',
                          selesaiDicuci.toString(),
                        ),
                        const Divider(height: 32),
                        _buildSummaryRow(
                          'Pendapatan Diterima',
                          'Rp $totalTransaksi',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        title: Text(
                          'Status Operator',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      for (final operator in provider.operatorList)
                        ListTile(
                          title: Text(operator['name'] as String? ?? '-'),
                          subtitle: Text(
                            operator['status_operasional'] as String? ??
                                'menganggur',
                          ),
                          trailing: Icon(
                            operator['status_operasional'] == 'bekerja'
                                ? Icons.work
                                : Icons.hourglass_empty,
                          ),
                          onTap: () => openDetailedView(
                            context,
                            title: 'Detail Status Operator',
                            data: operator,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  bool _isToday(Map<String, dynamic> transaction) {
    final createdAt = DateTime.tryParse(
      transaction['created_at'] as String? ?? '',
    )?.toLocal();
    final now = DateTime.now();
    return createdAt != null &&
        createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  int _amount(Map<String, dynamic> transaction) {
    final amount = transaction['total_harga'];
    return amount is num ? amount.toInt() : 0;
  }
}

class _CashierActionCard extends StatelessWidget {
  const _CashierActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.last,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
