import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:berkah_mobile/screens/detailed_view_screen.dart';

void main() {
  testWidgets('shows key account details without exposing internal fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DetailedViewScreen(
          title: 'Detail Akun',
          data: {
            'name': 'Rizki',
            'email': 'rizki@example.test',
            'role': 'operator',
            'nik': '2601',
            'password': 'secret',
            'remember_token': 'internal-token',
            'email_verified_at': '2026-11-03T01:00:00Z',
          },
        ),
      ),
    );

    expect(find.text('Rizki'), findsOneWidget);
    expect(find.text('rizki@example.test'), findsOneWidget);
    expect(find.text('2601'), findsOneWidget);
    expect(find.text('secret'), findsNothing);
    expect(find.text('internal-token'), findsNothing);
    expect(find.text('2026-11-03T01:00:00Z'), findsNothing);
  });

  testWidgets('summarizes transaction collections instead of dumping them', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DetailedViewScreen(
          title: 'Rincian Pendapatan',
          data: {
            'total_pendapatan': 25000,
            'transaksi': [
              {'no_polisi': 'B 1234 XYZ', 'total_harga': 25000},
            ],
          },
        ),
      ),
    );

    expect(find.text('25000'), findsOneWidget);
    expect(find.textContaining('1 transaksi tercatat.'), findsOneWidget);
    expect(find.text('B 1234 XYZ'), findsNothing);
  });

  testWidgets('shows operator status cards instead of raw map data', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DetailedViewScreen(
          title: 'Status Operator',
          data: {
            'operator': [
              {'id': 42, 'name': 'Rizki', 'status_operasional': 'bekerja'},
            ],
          },
        ),
      ),
    );

    expect(find.text('Rizki'), findsOneWidget);
    expect(find.text('Bekerja'), findsOneWidget);
    expect(find.textContaining('{id:'), findsNothing);
    expect(find.text('42'), findsNothing);
  });

  testWidgets('shows member vehicles and profile without raw map output', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DetailedViewScreen(
          title: 'Detail Member',
          data: {
            'name': 'Rizki',
            'email': 'rizki@example.test',
            'member': {'no_whatsapp': '+628123456789'},
            'kendaraan': [
              {
                'no_polisi': 'B 1234 XYZ',
                'merk_kendaraan': 'Honda',
                'model_kendaraan': 'Beat',
                'jenis_kendaraan': 'motor',
                'user_id': 42,
              },
            ],
          },
        ),
      ),
    );

    expect(find.text('Profil member'), findsOneWidget);
    expect(find.text('+628123456789'), findsOneWidget);
    expect(find.text('Kendaraan terdaftar (1)'), findsOneWidget);
    expect(find.text('B 1234 XYZ'), findsOneWidget);
    expect(find.text('Honda Beat • Motor'), findsOneWidget);
    expect(find.textContaining('{no_polisi:'), findsNothing);
    expect(find.text('42'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'formats vehicle and service dates with section-specific labels',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DetailedViewScreen(
            title: 'Detail Transaksi',
            data: {
              'kendaraan': {
                'no_polisi': 'B 2929 BYD',
                'created_at': '2026-10-31T16:51:54.000000Z',
              },
              'layanan': {
                'nama_layanan': 'Clean Normal',
                'created_at': '2026-10-27T15:43:35.000000Z',
              },
            },
          ),
        ),
      );

      expect(find.text('Kendaraan terdaftar'), findsOneWidget);
      expect(find.text('Layanan dibuat'), findsOneWidget);
      expect(find.textContaining('2026-10-31T'), findsNothing);
      expect(find.textContaining('2026-10-27T'), findsNothing);
      expect(find.textContaining('31 Okt 2026'), findsOneWidget);
      expect(find.textContaining('27 Okt 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
