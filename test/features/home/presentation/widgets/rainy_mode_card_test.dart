import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/widgets/rainy_mode_card.dart';

void main() {
  group('RainyModeCard', () {
    testWidgets('顯示雨天備案文字與 Switch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RainyModeCard(value: false, onChanged: (_) {})),
        ),
      );

      expect(find.text('雨天備案（只看室內景點）'), findsOneWidget);
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('點擊 Switch 觸發 onChanged', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RainyModeCard(
              value: false,
              onChanged: (value) => result = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(result, isTrue);
    });
  });
}
