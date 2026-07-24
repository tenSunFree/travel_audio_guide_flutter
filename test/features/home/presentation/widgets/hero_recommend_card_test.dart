import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/home/domain/entities/home_state.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/widgets/hero_recommend_card.dart';

HomeRecommendCard _buildCard({
  String title = '台北 101',
  String subtitle = '信義區・地標建築',
  String? imageUrl,
  String badgeText = '熱門推薦',
  String? reasonText,
  RecommendStatus status = RecommendStatus.openNow,
  HomeRecommendType type = HomeRecommendType.attraction,
  String emoji = '🏙️',
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

void main() {
  group('HeroRecommendCard', () {
    testWidgets('imageUrl 為 null 時顯示 fallback emoji', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HeroRecommendCard(card: _buildCard())),
        ),
      );
      expect(find.text('🏙️'), findsOneWidget);
    });

    testWidgets('顯示標題、副標題與類型標籤', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroRecommendCard(
              card: _buildCard(type: HomeRecommendType.activity),
            ),
          ),
        ),
      );
      expect(find.text('台北 101'), findsOneWidget);
      expect(find.text('信義區・地標建築'), findsOneWidget);
      expect(find.text('活動展演'), findsOneWidget);
      expect(find.text('熱門推薦'), findsOneWidget);
    });

    testWidgets('景點類型顯示「景點推薦」，語音導覽類型顯示「語音導覽」', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroRecommendCard(
              card: _buildCard(type: HomeRecommendType.attraction),
            ),
          ),
        ),
      );
      expect(find.text('景點推薦'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroRecommendCard(
              card: _buildCard(type: HomeRecommendType.audioGuide),
            ),
          ),
        ),
      );
      expect(find.text('語音導覽'), findsOneWidget);
    });

    testWidgets('reasonText 為 null 時不顯示推薦原因', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HeroRecommendCard(card: _buildCard())),
        ),
      );
      expect(find.text('步行 5 分鐘可達'), findsNothing);
    });

    testWidgets('reasonText 有值時顯示推薦原因', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroRecommendCard(card: _buildCard(reasonText: '步行 5 分鐘可達')),
          ),
        ),
      );
      expect(find.text('步行 5 分鐘可達'), findsOneWidget);
    });

    testWidgets('點擊「查看詳情」觸發 onViewDetail', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroRecommendCard(
              card: _buildCard(),
              onViewDetail: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('查看詳情'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('顯示「導航」按鈕（不點擊，避免觸發平台外掛）', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HeroRecommendCard(card: _buildCard())),
        ),
      );
      expect(find.text('導航'), findsOneWidget);
    });
  });
}
