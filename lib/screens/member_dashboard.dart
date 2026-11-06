import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/transaksi_provider.dart';
import '../services/member_service.dart';
import 'detailed_view_screen.dart';
import 'kasir_profil_tab.dart';
import 'main_scaffold.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransaksiProvider>().loadTransaksi(role: 'member');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      role: 'member',
      pages: const [
        _MemberHomeTab(),
        _MemberHistoryTab(),
        _MemberVehiclesTab(),
        KasirProfilTab(),
      ],
      navItems: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car_outlined),
          activeIcon: Icon(Icons.directions_car),
          label: 'Kendaraan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}

class _MemberHomeTab extends StatefulWidget {
  const _MemberHomeTab();

  @override
  State<_MemberHomeTab> createState() => _MemberHomeTabState();
}

class _MemberHomeTabState extends State<_MemberHomeTab> {
  final MemberService _memberService = MemberService();
  late Future<Map<String, dynamic>> _loyaltyFuture;

  @override
  void initState() {
    super.initState();
    _loyaltyFuture = _memberService.fetchMyLoyalty();
  }

  Future<void> _refresh() async {
    await context.read<TransaksiProvider>().loadTransaksi(role: 'member');
    if (mounted) {
      setState(() {
        _loyaltyFuture = _memberService.fetchMyLoyalty();
      });
    }
  }

  Widget _buildLoyaltyCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loyaltyFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: const Text('Progres promo tidak dapat dimuat.'),
              subtitle: Text(snapshot.error.toString()),
              trailing: IconButton(
                tooltip: 'Coba muat ulang progres promo',
                onPressed: () {
                  setState(() {
                    _loyaltyFuture = _memberService.fetchMyLoyalty();
                  });
                },
                icon: const Icon(Icons.refresh),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Card(
            child: ListTile(
              leading: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Memuat progres promo...'),
            ),
          );
        }

        final loyalty = snapshot.data!;
        final promoValue = loyalty['promo'];
        if (promoValue is! Map) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.local_offer_outlined),
              title: Text('Belum ada promo aktif.'),
            ),
          );
        }

        final promo = Map<String, dynamic>.from(promoValue);
        final completedWashes =
            int.tryParse(loyalty['completed_washes']?.toString() ?? '') ?? 0;
        final threshold =
            int.tryParse(promo['wash_threshold']?.toString() ?? '') ?? 5;
        final rewardAvailable = loyalty['reward_available'] == true;
        final rewardReserved = loyalty['reward_reserved'] == true;
        final progress = threshold > 0
            ? (completedWashes / threshold).clamp(0.0, 1.0).toDouble()
            : 0.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2186E8), Color(0xFF2652B9), Color(0xFF634FC0)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF365FB5).withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -32,
                top: -34,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 18,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          promo['name'] as String? ?? 'Promo loyalitas',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '$completedWashes/$threshold',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 9,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    rewardReserved
                        ? 'Hadiah gratis sedang diproses untuk transaksi Anda.'
                        : rewardAvailable
                        ? 'Hadiah cuci gratis tersedia. Beri tahu kasir saat membuat transaksi untuk mengklaimnya.'
                        : 'Cuci $threshold kali sampai selesai dan lunas untuk mendapat 1 cucian gratis.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name =
        context.watch<AuthProvider>().user?['name'] as String? ?? 'Member';

    return SafeArea(
      child: Consumer<TransaksiProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.transaksiList.isEmpty) {
            return _LoadError(
              message: provider.errorMessage!,
              onRetry: () => provider.loadTransaksi(role: 'member'),
            );
          }

          final transactions = provider.transaksiList;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Halo, $name',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pantau status kendaraan dan riwayat pencucian Anda.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                _buildLoyaltyCard(),
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xFF1769AA),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => openDetailedView(
                      context,
                      title: 'Riwayat Pencucian Member',
                      data: {
                        'jumlah_pencucian': transactions.length,
                        'transaksi': transactions,
                      },
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${transactions.length}x',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Total pencucian',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.local_car_wash,
                            color: Colors.white,
                            size: 42,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pencucian terakhir',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (transactions.isEmpty)
                  const _EmptyState(message: 'Belum ada riwayat pencucian.')
                else
                  ...transactions
                      .take(3)
                      .map(
                        (transaction) =>
                            _TransactionCard(transaction: transaction),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MemberHistoryTab extends StatelessWidget {
  const _MemberHistoryTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<TransaksiProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.transaksiList.isEmpty) {
            return _LoadError(
              message: provider.errorMessage!,
              onRetry: () => provider.loadTransaksi(role: 'member'),
            );
          }
          if (provider.transaksiList.isEmpty) {
            return const _EmptyState(message: 'Belum ada riwayat pencucian.');
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadTransaksi(role: 'member'),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Riwayat pencucian',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ...provider.transaksiList.map(
                  (transaction) => _TransactionCard(transaction: transaction),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MemberVehiclesTab extends StatefulWidget {
  const _MemberVehiclesTab();

  @override
  State<_MemberVehiclesTab> createState() => _MemberVehiclesTabState();
}

class _MemberVehiclesTabState extends State<_MemberVehiclesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransaksiProvider>().loadVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<TransaksiProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.kendaraanList.isEmpty) {
            return _LoadError(
              message: provider.errorMessage!,
              onRetry: provider.loadVehicles,
            );
          }
          if (provider.kendaraanList.isEmpty) {
            return const _EmptyState(message: 'Belum ada kendaraan terdaftar.');
          }

          return RefreshIndicator(
            onRefresh: provider.loadVehicles,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Kendaraan saya',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ...provider.kendaraanList.map(
                  (vehicle) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text(vehicle['no_polisi'] as String? ?? '-'),
                      subtitle: Text(
                        vehicle['merk_kendaraan'] as String? ?? '-',
                      ),
                      onTap: () => openDetailedView(
                        context,
                        title: 'Detail Kendaraan ${vehicle['no_polisi'] ?? ''}',
                        data: Map<String, dynamic>.from(vehicle),
                      ),
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

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final vehicle = transaction['kendaraan'] as Map<String, dynamic>? ?? {};
    final service = transaction['layanan'] as Map<String, dynamic>? ?? {};
    final amount = transaction['total_harga'] ?? 0;
    final serviceName =
        transaction['nama_layanan'] as String? ??
        service['nama_layanan'] as String? ??
        '-';
    final isCancelled = transaction['cancelled_at'] != null;
    final status = transaction['status_cucian'] as String? ?? 'menunggu';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.local_car_wash),
        title: Text(vehicle['no_polisi'] as String? ?? '-'),
        subtitle: isCancelled
            ? Text(
                '$serviceName\nDibatalkan: ${transaction['cancel_reason'] ?? 'Alasan tidak dicatat'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : Text(serviceName),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Rp $amount',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              isCancelled ? 'DIBATALKAN' : status.toUpperCase(),
              style: TextStyle(color: isCancelled ? Colors.red : null),
            ),
          ],
        ),
        onTap: () => openDetailedView(
          context,
          title: 'Detail Transaksi ${vehicle['no_polisi'] ?? ''}',
          data: Map<String, dynamic>.from(transaction),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
