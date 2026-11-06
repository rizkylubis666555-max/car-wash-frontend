import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:berkah_mobile/widgets/owner_config_section_header.dart';

void main() {
  testWidgets('shows section details and triggers refresh', (tester) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OwnerConfigSectionHeader(
            title: 'Kelola layanan',
            subtitle: 'Atur jenis layanan dan harga cuci',
            icon: Icons.local_car_wash_rounded,
            itemCount: 4,
            onRefresh: () => refreshCount++,
          ),
        ),
      ),
    );

    expect(find.text('Kelola layanan'), findsOneWidget);
    expect(find.text('Atur jenis layanan dan harga cuci'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.byTooltip('Muat ulang Kelola layanan'));
    expect(refreshCount, 1);
  });
}
