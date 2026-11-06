import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:berkah_mobile/providers/transaksi_provider.dart';
import 'package:berkah_mobile/screens/kasir_antrean_tab.dart';
import 'package:berkah_mobile/services/transaksi_service.dart';
import 'package:berkah_mobile/theme/app_theme.dart';

void main() {
  testWidgets('renders waiting queue actions without layout overflow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'token': 'qa-token'});
    final service = TransaksiService(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 12,
                'status_cucian': 'menunggu',
                'status_bayar': 'belum',
                'cancelled_at': null,
                'kendaraan': {
                  'no_polisi': 'QA 8001 TST',
                  'merk_kendaraan': 'Honda',
                  'jenis_kendaraan': 'motor',
                },
                'layanan': {'nama_layanan': 'Cuci QA'},
              },
            ],
          }),
          200,
        );
      }),
    );
    final provider = TransaksiProvider(service: service);
    await provider.loadTransaksi(role: 'operator');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: KasirAntreanTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('QA 8001 TST'), findsOneWidget);
    expect(find.text('MENUNGGU'), findsOneWidget);
    expect(find.text('Menunggu'), findsOneWidget);
    expect(find.text('Dicuci'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
