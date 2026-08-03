import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/home/domain/entities/home_state.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/widgets/recommend_list_tile.dart';

HomeRecommendCard _buildCard({
  String title = '大安森林公園',
  String subtitle = '大安區',
  String? imageUrl,
  String badgeText = '現正開放',
  String? reasonText,
  RecommendStatus status = RecommendStatus.openNow,
  HomeRecommendType type = HomeRecommendType.attraction,
  String emoji = '🌳',
}) {
  return HomeRecommendCard(
    id: '1',
    title: title,
    subtitle: subtitle,
    imageUrl: imageUrl,
    badgeText: badgeText,
    distanceText: null,
    reasonText: reasonText,
    status: status,
    lat: 25.03,
    lng: 121.56,
    type: type,
    emoji: emoji,
  );
}

Widget _wrap(HomeRecommendCard card, {VoidCallback? onTap}) {
  return MaterialApp(
    home: Scaffold(
      body: RecommendListTile(card: card, onTap: onTap),
    ),
  );
}

void main() {
  group('RecommendListTile', () {
    testWidgets('type=activity 時顯示 emoji 日期徽章', (tester) async {
      await tester.pumpWidget(
        _wrap(_buildCard(type: HomeRecommendType.activity, emoji: '📅')),
      );
      expect(find.text('📅'), findsOneWidget);
      expect(find.text('活動'), findsOneWidget);
    });

    testWidgets('type=attraction 且 imageUrl 為 null 時顯示 fallback emoji', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(_buildCard()),
      );
      expect(find.text('🌳'), findsOneWidget);
      expect(find.text('景點'), findsOneWidget);
    });

    testWidgets('type=audioGuide 顯示對應標籤', (tester) async {
      await tester.pumpWidget(
        _wrap(_buildCard(type: HomeRecommendType.audioGuide)),
      );
      expect(find.text('語音導覽'), findsOneWidget);
    });

    testWidgets('顯示標題與 badgeText', (tester) async {
      await tester.pumpWidget(_wrap(_buildCard()));
      expect(find.text('大安森林公園'), findsOneWidget);
      expect(find.text('現正開放'), findsOneWidget);
    });

    testWidgets('subtitle 為空時不顯示', (tester) async {
      await tester.pumpWidget(_wrap(_buildCard(subtitle: '')));
      expect(find.text('大安區'), findsNothing);
    });

    testWidgets('subtitle 不為空時顯示', (tester) async {
      await tester.pumpWidget(_wrap(_buildCard()));
      expect(find.text('大安區'), findsOneWidget);
    });

    testWidgets('reasonText 為 null 時不顯示', (tester) async {
      await tester.pumpWidget(_wrap(_buildCard()));
      expect(find.text('步行 5 分鐘可達'), findsNothing);
    });

    testWidgets('reasonText 有值時顯示', (tester) async {
      await tester.pumpWidget(_wrap(_buildCard(reasonText: '步行 5 分鐘可達')));
      expect(find.text('步行 5 分鐘可達'), findsOneWidget);
    });

    testWidgets('點擊觸發 onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(_buildCard(), onTap: () => tapped = true));
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(tapped, isTrue);
    });

    // Verify each branch of _statusStyle() maps to the correct icon,
    // ensuring every switch path is exercised.
    final statusIconCases = <RecommendStatus, IconData>{
      RecommendStatus.ongoing: Icons.play_circle_outline,
      RecommendStatus.comingSoon: Icons.event_outlined,
      RecommendStatus.openNow: Icons.check_circle_outline,
      RecommendStatus.alwaysOpen: Icons.check_circle_outline,
      RecommendStatus.openUntil: Icons.schedule,
      RecommendStatus.closingSoon: Icons.hourglass_bottom_outlined,
      RecommendStatus.uncertain: Icons.help_outline,
    };

    for (final entry in statusIconCases.entries) {
      testWidgets('status=${entry.key} 顯示對應 icon', (tester) async {
        await tester.pumpWidget(_wrap(_buildCard(status: entry.key)));
        expect(find.byIcon(entry.value), findsOneWidget);
      });
    }
  });
}
