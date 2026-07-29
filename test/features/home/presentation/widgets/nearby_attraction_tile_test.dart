import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/widgets/nearby_attraction_tile.dart';

void main() {
  testWidgets(
    'NearbyAttractionTile renders name and meta, and responds to tap',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NearbyAttractionTile(
              name: '測試景點',
              distric: '信義區',
              distanceLabel: '500m',
              imageUrl: null,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('測試景點'), findsOneWidget);
      expect(find.textContaining('500m'), findsOneWidget);
      expect(find.textContaining('信義區'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'NearbyAttractionTile falls back to placeholder icon when imageUrl is null',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NearbyAttractionTile(
              name: 'X',
              distric: '',
              distanceLabel: null,
              imageUrl: null,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    },
  );
}
