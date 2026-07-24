import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/home/domain/entities/home_state.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/widgets/period_chips.dart';

void main() {
  group('PeriodChips', () {
    testWidgets('顯示四個時段', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodChips(selected: HomePeriod.morning, onSelected: (_) {}),
          ),
        ),
      );
      expect(find.text('早上'), findsOneWidget);
      expect(find.text('下午'), findsOneWidget);
      expect(find.text('傍晚'), findsOneWidget);
      expect(find.text('夜間'), findsOneWidget);
    });

    testWidgets('點擊時段觸發 onSelected', (tester) async {
      HomePeriod? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodChips(
              selected: HomePeriod.morning,
              onSelected: (value) => selected = value,
            ),
          ),
        ),
      );
      await tester.tap(find.text('下午'));
      await tester.pump();
      expect(selected, HomePeriod.afternoon);
    });
  });
}
