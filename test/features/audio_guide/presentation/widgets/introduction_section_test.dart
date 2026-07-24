import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/widgets/introduction_section.dart';

void main() {
  group('IntroductionSection', () {
    testWidgets('顯示標題與介紹文字', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IntroductionSection(
              pageTitle: '台北 101',
              text: '這是一段介紹文字，測試用。',
            ),
          ),
        ),
      );
      expect(find.text('景點介紹'), findsOneWidget);
      expect(find.text('這是一段介紹文字，測試用。'), findsOneWidget);
      expect(find.text('展開全文 ›'), findsOneWidget);
    });

    testWidgets('點擊展開全文，開啟 BottomSheet 顯示完整標題與內文', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IntroductionSection(pageTitle: '台北 101', text: '完整介紹內容'),
          ),
        ),
      );
      await tester.tap(find.text('展開全文 ›'));
      await tester.pumpAndSettle();
      // The BottomSheet contains the title and body; they may appear more than once
      // (the main body remains in the background as well).
      expect(find.text('台北 101'), findsOneWidget);
      expect(find.text('完整介紹內容'), findsWidgets);
      // Tapping the close icon in the top-right should dismiss the sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });
  });
}
