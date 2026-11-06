import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:berkah_mobile/widgets/slide_to_finish_control.dart';

void main() {
  testWidgets('completes only after the control is dragged to the end', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SlideToFinishControl(
                onComplete: () async {
                  completed = true;
                  return true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(SlideToFinishControl), const Offset(250, 0));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(find.text('Tugas selesai'), findsOneWidget);
  });

  testWidgets('resets the control when completing the task fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SlideToFinishControl(onComplete: () async => false),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(SlideToFinishControl), const Offset(250, 0));
    await tester.pumpAndSettle();

    expect(find.text('Geser untuk selesai'), findsOneWidget);
  });
}
