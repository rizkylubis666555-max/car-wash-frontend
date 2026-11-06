import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:berkah_mobile/main.dart';

void main() {
  testWidgets('application shows login for a signed-out visitor', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('CAR WASH'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('member registration requires a WhatsApp number', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daftar sebagai member'));
    await tester.pumpAndSettle();

    expect(find.text('Nomor WhatsApp *'), findsOneWidget);

    await tester.ensureVisible(find.text('Daftar & Masuk'));
    await tester.tap(find.text('Daftar & Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Semua kolom pendaftaran wajib diisi.'), findsOneWidget);
  });
}
