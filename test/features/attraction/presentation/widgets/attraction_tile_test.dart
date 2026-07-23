import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/widgets/attraction_tile.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

Attraction _buildAttraction({
  String name = '台北 101',
  double? nlat = 25.0330,
  double? elong = 121.5654,
  String distric = '信義區',
  List<AttractionImage> images = const [],
}) {
  return Attraction(
    id: 1,
    name: name,
    introduction: '測試介紹',
    openTime: '09:00-22:00',
    distric: distric,
    address: '台北市信義區信義路五段7號',
    tel: '02-12345678',
    officialSite: '',
    facebook: '',
    ticket: '免費',
    remind: '',
    modified: '2026-01-01',
    url: 'https://example.com/attraction/1',
    categories: const [],
    targets: const [],
    friendlies: const [],
    images: images,
    nlat: nlat,
    elong: elong,
  );
}

void main() {
  group('AttractionTile', () {
    testWidgets('renders attraction name', (tester) async {
      await tester.pumpWidget(
        _wrap(AttractionTile(attraction: _buildAttraction(), onTap: () {})),
      );
      expect(find.text('台北 101'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          AttractionTile(
            attraction: _buildAttraction(),
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('does not show distance without user location', (tester) async {
      await tester.pumpWidget(
        _wrap(AttractionTile(attraction: _buildAttraction(), onTap: () {})),
      );
      expect(find.textContaining('距你'), findsNothing);
    });

    testWidgets('shows distance with valid coordinates', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AttractionTile(
            attraction: _buildAttraction(),
            userLat: 25.0340,
            userLng: 121.5645,
            onTap: () {},
          ),
        ),
      );
      expect(find.textContaining('距你'), findsOneWidget);
    });

    // Note: isValidCoordinate treats (0,0) as invalid as well — it's not only null that's invalid
    testWidgets('does not show distance for invalid (0,0) coordinate', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AttractionTile(
            attraction: _buildAttraction(nlat: 0.0, elong: 0.0),
            userLat: 25.0340,
            userLng: 121.5645,
            onTap: () {},
          ),
        ),
      );
      expect(find.textContaining('距你'), findsNothing);
    });

    testWidgets('shows placeholder emoji when no image', (tester) async {
      await tester.pumpWidget(
        _wrap(AttractionTile(attraction: _buildAttraction(), onTap: () {})),
      );
      expect(find.text('📍'), findsOneWidget); // Default emoji when no category
    });
  });
}
