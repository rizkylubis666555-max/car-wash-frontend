import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:berkah_mobile/providers/auth_provider.dart';
import 'package:berkah_mobile/providers/transaksi_provider.dart';
import 'package:berkah_mobile/screens/main_scaffold.dart';

void main() {
  testWidgets('keeps the bottom of scrollable pages above global navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => TransaksiProvider()),
        ],
        child: MaterialApp(
          home: MainScaffold(
            role: 'owner',
            pages: [
              Scaffold(
                body: ListView(
                  children: [
                    for (var index = 0; index < 30; index++)
                      SizedBox(
                        height: 48,
                        child: Center(child: Text('Pengaturan $index')),
                      ),
                    const SizedBox(
                      height: 72,
                      child: Center(child: Text('Bagian paling bawah')),
                    ),
                  ],
                ),
              ),
              const Scaffold(body: Center(child: Text('Profil'))),
            ],
            navItems: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    final bottomContent = tester.getRect(find.text('Bagian paling bawah'));
    final navigationBar = tester.getRect(find.byType(NavigationBar));
    expect(bottomContent.bottom, lessThanOrEqualTo(navigationBar.top));
    expect(tester.takeException(), isNull);
  });
}
