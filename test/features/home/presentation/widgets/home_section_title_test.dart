import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/widgets/home_section_title.dart';

void main() {
  group('HomeSectionTitle', () {
    testWidgets('顯示標題與動作文字', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeSectionTitle(
              title: '附近推薦',
              action: '查看全部',
              onActionTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('附近推薦'), findsOneWidget);
      expect(find.text('查看全部'), findsOneWidget);
    });

    testWidgets('點擊 action 文字觸發 onActionTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeSectionTitle(
              title: '附近推薦',
              action: '查看全部',
              onActionTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('查看全部'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('onActionTap 為 null 時不會出錯', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeSectionTitle(title: '附近推薦', action: '查看全部'),
          ),
        ),
      );
      await tester.tap(find.text('查看全部'));
      await tester.pump();
      // Test passes if no exception is thrown
    });
  });
}
