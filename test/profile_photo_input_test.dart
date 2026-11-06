import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:berkah_mobile/widgets/profile_photo_input.dart';

void main() {
  testWidgets('offers recommended camera capture and gallery selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProfilePhotoInput(onPhotoSelected: (_) async {})),
      ),
    );

    expect(find.text('Kamera (disarankan)'), findsOneWidget);
    expect(find.text('Pilih gambar'), findsOneWidget);
  });
}
