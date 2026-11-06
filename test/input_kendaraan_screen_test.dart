import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:berkah_mobile/providers/transaksi_provider.dart';
import 'package:berkah_mobile/screens/input_kendaraan_screen.dart';
import 'package:berkah_mobile/services/catalog_service.dart';
import 'package:berkah_mobile/services/member_service.dart';
import 'package:berkah_mobile/services/operator_service.dart';
import 'package:berkah_mobile/services/transaksi_service.dart';
import 'package:berkah_mobile/services/vehicle_brand_service.dart';

void main() {
  testWidgets(
    'shows vehicle type and matching services for a member without vehicles',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'token': 'qa-token',
        'user': jsonEncode({'id': 10, 'role': 'kasir'}),
      });
      final client = MockClient((request) async {
        final response = switch (request.url.path) {
          '/api/transaksi' => {'data': []},
          '/api/layanan' => {
            'data': [
              {
                'id': 1,
                'nama_layanan': 'Cuci Motor QA',
                'jenis_kendaraan': 'motor',
                'harga': 12000,
              },
            ],
          },
          '/api/members' => {
            'data': [
              {
                'id': 12,
                'name': 'QA Member',
                'email': 'qa-member@example.test',
                'kendaraan': [],
              },
            ],
          },
          '/api/vehicle-brands' => {
            'data': [
              {'id': 1, 'name': 'Honda', 'is_active': true},
            ],
          },
          '/api/operators' => {'data': []},
          _ => {'message': 'Unexpected request'},
        };

        return http.Response(
          jsonEncode(response),
          response.containsKey('data') ? 200 : 404,
        );
      });
      final provider = TransaksiProvider(
        service: TransaksiService(client: client),
        catalogService: CatalogService(client: client),
        memberService: MemberService(client: client),
        operatorService: OperatorService(client: client),
        vehicleBrandService: VehicleBrandService(client: client),
      );
      await provider.loadTransaksi(role: 'kasir');

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: InputKendaraanScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Member'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Cari nama atau ID member',
        ),
        'QA Member',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('QA Member').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Member ini belum memiliki kendaraan. Isi data kendaraan baru.',
        ),
        findsOneWidget,
      );
      expect(find.text('Motor'), findsOneWidget);
      expect(find.text('Mobil'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -280));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Motor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Motor'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Cuci Motor QA'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Cuci Motor QA'), findsOneWidget);
      expect(find.text('Rp 12000'), findsOneWidget);
    },
  );
}
