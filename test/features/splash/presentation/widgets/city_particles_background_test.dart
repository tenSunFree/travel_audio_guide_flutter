import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/splash/presentation/widgets/city_particles_background.dart';

void main() {
  group('CityParticlesBackground', () {
    testWidgets(
      'renders and repaints across animation frames without throwing',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 300,
                child: CityParticlesBackground(),
              ),
            ),
          ),
        );
        expect(find.byType(CityParticlesBackground), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
        // Advance through several animation frames so
        // `_MapBackgroundPainter.paint` runs repeatedly with different
        // `progress` values — this exercises the per-dot opacity animation,
        // the route path drawing, and the cascade-notation star drawing
        // calls (`canvas..drawCircle()..drawCircle()...`).
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 700));
        }
        // Reaching this line without a thrown exception means every
        // `canvas.drawCircle` / `canvas.drawPath` call in the painter
        // executed successfully across multiple `progress` values.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('disposes its AnimationController cleanly on removal', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CityParticlesBackground())),
      );
      await tester.pump(const Duration(milliseconds: 300));
      // Replacing the tree removes CityParticlesBackground, triggering
      // State.dispose() and AnimationController.dispose().
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
