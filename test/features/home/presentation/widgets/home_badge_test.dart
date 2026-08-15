import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/widgets/home_badge.dart';

void main() {
  group('HomeBadge', () {
    testWidgets('顯示文字並套用指定顏色', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeBadge(
              text: '景點推薦',
              backgroundColor: Colors.blue,
              textColor: Colors.white,
            ),
          ),
        ),
      );
      expect(find.text('景點推薦'), findsOneWidget);
      final text = tester.widget<Text>(find.text('景點推薦'));
      expect(text.style?.color, Colors.white);
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, Colors.blue);
    });

    testWidgets('過長文字會被 ellipsis 截斷（maxLines: 1）', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 40,
              child: HomeBadge(
                text: '這是一段很長很長很長的文字內容',
                backgroundColor: Colors.blue,
                textColor: Colors.white,
              ),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('這是一段很長很長很長的文字內容'));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });
}
