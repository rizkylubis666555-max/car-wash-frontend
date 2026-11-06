import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaksi_provider.dart';
import 'detailed_view_screen.dart';

class KasirRiwayatTab extends StatelessWidget {
  const KasirRiwayatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: Color(0xFF2369C8)),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat transaksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Transaksi yang sudah dibayar',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<TransaksiProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Hanya ambil transaksi yang status bayarnya lunas
                final listLunas = provider.transaksiList
                    .where((t) => t['status_bayar'] == 'lunas')
                    .toList();

                if (listLunas.isEmpty) {
                  return const Center(
                    child: Text('Belum ada riwayat transaksi lunas.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listLunas.length,
                  itemBuilder: (context, index) {
                    final trx = listLunas[index];
                    final noPolisi = trx['kendaraan']?['no_polisi'] ?? '-';
                    final layanan =
                        trx['nama_layanan'] ??
                        trx['layanan']?['nama_layanan'] ??
                        '-';
                    final harga = trx['total_harga'] ?? 0;

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          noPolisi,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(layanan),
                        onTap: () => openDetailedView(
                          context,
                          title: 'Detail Transaksi $noPolisi',
                          data: Map<String, dynamic>.from(trx),
                        ),
                        trailing: Text(
                          trx['total_harga'] == null
                              ? 'Harga tidak tercatat'
                              : 'Rp $harga',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
