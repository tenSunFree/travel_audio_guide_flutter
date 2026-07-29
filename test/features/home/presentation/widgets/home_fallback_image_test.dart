import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/widgets/home_fallback_image.dart';

void main() {
  group('HomeFallbackImage', () {
    testWidgets('顯示傳入的 emoji', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeFallbackImage('🏛️'))),
      );
      expect(find.text('🏛️'), findsOneWidget);
    });
  });
}
