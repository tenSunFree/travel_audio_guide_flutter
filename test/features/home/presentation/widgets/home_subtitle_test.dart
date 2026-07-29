import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/widgets/home_subtitle.dart';

void main() {
  group('HomeSubtitle', () {
    testWidgets('顯示傳入的 subtitle 文字', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomeSubtitle(subtitle: '適合晨間散步、步道與戶外景點')),
        ),
      );
      expect(find.text('適合晨間散步、步道與戶外景點'), findsOneWidget);
    });
  });
}
