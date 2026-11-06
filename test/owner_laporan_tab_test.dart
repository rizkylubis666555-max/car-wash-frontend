import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:berkah_mobile/providers/transaksi_provider.dart';
import 'package:berkah_mobile/screens/owner_laporan_tab.dart';
import 'package:berkah_mobile/services/operator_service.dart';
import 'package:berkah_mobile/services/transaksi_service.dart';

void main() {
  testWidgets('renders report filters and summary without layout errors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'token': 'qa-token'});
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'data': []}), 200),
    );
    final provider = TransaksiProvider(
      service: TransaksiService(client: client),
      operatorService: OperatorService(client: client),
    );
    await provider.loadTransaksi(role: 'owner');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: OwnerLaporanTab())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Laporan operasional'), findsOneWidget);
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
    expect(find.text('Pendapatan diterima'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
