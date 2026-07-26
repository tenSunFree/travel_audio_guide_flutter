import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/widgets/home_empty_card.dart';

void main() {
  testWidgets('顯示傳入的訊息文字', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeEmptyCard(message: '目前沒有推薦內容')),
      ),
    );
    expect(find.text('目前沒有推薦內容'), findsOneWidget);
  });
}
