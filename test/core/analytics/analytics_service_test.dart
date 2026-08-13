import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/analytics/analytics_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late MockFirebaseAnalytics analytics;

  setUp(() {
    analytics = MockFirebaseAnalytics();
    AnalyticsService.debugSetInstance(analytics);
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(AnalyticsService.debugResetInstance);

  group('AnalyticsService', () {
    test('logAttractionViewed 正確傳遞事件名稱與參數', () async {
      await AnalyticsService.logAttractionViewed(id: 1, name: '台北 101');
      verify(
        () => analytics.logEvent(
          name: 'attraction_viewed',
          parameters: {'attraction_id': 1, 'attraction_name': '台北 101'},
        ),
      ).called(1);
    });

    test('logEvent 拋出例外時不應該向外拋出(靜默處理)', () async {
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenThrow(Exception('network error'));
      await expectLater(
        AnalyticsService.logAttractionViewed(id: 1, name: '台北 101'),
        completes,
      );
    });
  });
}
