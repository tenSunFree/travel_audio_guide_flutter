import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/widgets/step_count_badge.dart';

void main() {
  group('StepCountBadge', () {
    testWidgets('顯示公尺距離', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StepCountBadge(steps: 1234, distance: 850)),
        ),
      );
      expect(find.text('1234 步 · 850 公尺'), findsOneWidget);
    });

    testWidgets('顯示公里距離', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StepCountBadge(steps: 3000, distance: 1500)),
        ),
      );
      expect(find.text('3000 步 · 1.5 公里'), findsOneWidget);
    });
  });
}
