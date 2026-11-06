import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaksi_provider.dart';
import 'detailed_view_screen.dart';

class OwnerHomeTab extends StatelessWidget {
  const OwnerHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<TransaksiProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.transaksiList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => provider.loadTransaksi(role: 'owner'),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final todayTransactions = provider.transaksiList.where((transaction) {
            if (transaction['cancelled_at'] != null) {
              return false;
            }
            final createdAt = DateTime.tryParse(
              transaction['created_at'] as String? ?? '',
            )?.toLocal();
            return createdAt != null &&
                createdAt.year == now.year &&
                createdAt.month == now.month &&
                createdAt.day == now.day;
          }).toList();
          final paidTransactions = provider.transaksiList
              .where((transaction) => transaction['cancelled_at'] == null)
              .where((transaction) => transaction['status_bayar'] == 'lunas')
              .where((transaction) {
                final paidAt = DateTime.tryParse(
                  transaction['paid_at'] as String? ?? '',
                )?.toLocal();

                return paidAt != null &&
                    paidAt.year == now.year &&
                    paidAt.month == now.month &&
                    paidAt.day == now.day;
              })
              .toList();
          final totalPendapatan = paidTransactions.fold<int>(
            0,
            (sum, transaction) => sum + _amount(transaction),
          );
          final totalTransaksi = paidTransactions.length;
          final kendaraanMasuk = todayTransactions.length;
          final waiting = provider.transaksiList
              .where((transaction) => transaction['cancelled_at'] == null)
              .where(
                (transaction) => transaction['status_cucian'] == 'menunggu',
              )
              .toList();
          final washing = provider.transaksiList
              .where((transaction) => transaction['cancelled_at'] == null)
              .where((transaction) => transaction['status_cucian'] == 'dicuci')
              .toList();
          final busyOperatorIds = washing
              .map((transaction) => transaction['operator_id']?.toString())
              .whereType<String>()
              .toSet();
          const months = [
            'Januari',
            'Februari',
            'Maret',
            'April',
            'Mei',
            'Juni',
            'Juli',
            'Agustus',
            'September',
            'Oktober',
            'November',
            'Desember',
          ];
          final dateLabel = '${now.day} ${months[now.month - 1]} ${now.year}';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => openDetailedView(
                      context,
                      title: 'Ringkasan Operasi $dateLabel',
                      data: {
                        'tanggal': dateLabel,
                        'kendaraan_masuk': todayTransactions.length,
                        'pendapatan_diterima': paidTransactions.fold<int>(
                          0,
                          (sum, transaction) => sum + _amount(transaction),
                        ),
                        'transaksi': todayTransactions,
                      },
                    ),
                    child: Ink(
                      height: 142,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2388F0), Color(0xFF184FB9)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1E5BBF,
                            ).withValues(alpha: 0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -24,
                            top: -54,
                            child: _BannerOrb(size: 170),
                          ),
                          Positioned(
                            left: -44,
                            bottom: -96,
                            child: _BannerOrb(size: 180),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dateLabel,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'HARI INI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                    shadows: [
                                      Shadow(
                                        color: Color(0x660D357E),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Positioned(
                            right: 16,
                            bottom: 14,
                            child: Icon(
                              Icons.arrow_outward_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.18,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMetricCard(
                      'Pendapatan',
                      'Rp $totalPendapatan',
                      Icons.account_balance_wallet_rounded,
                      const Color(0xFF2E9D68),
                      onTap: () => openDetailedView(
                        context,
                        title: 'Rincian Pendapatan',
                        data: {
                          'total_pendapatan': totalPendapatan,
                          'transaksi': paidTransactions,
                        },
                      ),
                    ),
                    _buildMetricCard(
                      'Transaksi',
                      '$totalTransaksi',
                      Icons.receipt_long_rounded,
                      const Color(0xFF3693D8),
                      onTap: () => openDetailedView(
                        context,
                        title: 'Rincian Transaksi',
                        data: {
                          'jumlah_transaksi_lunas': totalTransaksi,
                          'transaksi': paidTransactions,
                        },
                      ),
                    ),
                    _buildMetricCard(
                      'Kendaraan',
                      '$kendaraanMasuk Unit',
                      Icons.directions_car_rounded,
                      const Color(0xFFE6A62D),
                      onTap: () => openDetailedView(
                        context,
                        title: 'Rincian Kendaraan Masuk',
                        data: {
                          'jumlah_kendaraan_masuk': kendaraanMasuk,
                          'transaksi': todayTransactions,
                        },
                      ),
                    ),
                    _buildMetricCard(
                      'Menunggu',
                      '${waiting.length} Unit',
                      Icons.hourglass_bottom_rounded,
                      const Color(0xFFE16D4A),
                      onTap: () => openDetailedView(
                        context,
                        title: 'Antrean Menunggu',
                        data: {'jumlah': waiting.length, 'transaksi': waiting},
                      ),
                    ),
                    _buildMetricCard(
                      'Sedang dicuci',
                      '${washing.length} Unit',
                      Icons.local_car_wash_rounded,
                      const Color(0xFF397AC6),
                      onTap: () => openDetailedView(
                        context,
                        title: 'Tugas Sedang Dicuci',
                        data: {'jumlah': washing.length, 'transaksi': washing},
                      ),
                    ),
                    _buildMetricCard(
                      'Operator',
                      '${busyOperatorIds.length} Bekerja',
                      Icons.engineering_rounded,
                      const Color(0xFF8A65C5),
                      onTap: () => openDetailedView(
                        context,
                        title: 'Status Operator',
                        data: {
                          'operator': provider.operatorList
                              .map(
                                (operator) => {
                                  ...operator,
                                  'status_operasional':
                                      busyOperatorIds.contains(
                                        operator['id']?.toString(),
                                      )
                                      ? 'bekerja'
                                      : 'menganggur',
                                },
                              )
                              .toList(),
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFFCFDFE),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF536B8A).withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 6,
                offset: Offset(-2, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color.withValues(alpha: 0.82), color],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 23),
                  ),
                  const Spacer(),
                  Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F9),
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF44546A,
                          ).withValues(alpha: 0.12),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 21,
                      color: Color(0xFF52657D),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF52657D),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF172B4D),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _amount(Map<String, dynamic> transaction) {
    final amount = transaction['total_harga'] ?? 0;
    return amount is num ? amount.toInt() : 0;
  }
}

class _BannerOrb extends StatelessWidget {
  const _BannerOrb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 2,
        ),
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.01),
          ],
        ),
      ),
    );
  }
}
