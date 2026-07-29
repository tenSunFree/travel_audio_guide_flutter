import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_travel_audio_guide/core/preferences/shared_preferences_provider.dart';
import 'package:flutter_travel_audio_guide/features/onboarding/data/datasources/onboarding_local_data_source.dart';

class MockSharedPreferencesWithCache extends Mock
    implements SharedPreferencesWithCache {}

void main() {
  late MockSharedPreferencesWithCache prefs;
  late OnboardingLocalDataSource dataSource;

  setUp(() {
    prefs = MockSharedPreferencesWithCache();
    dataSource = OnboardingLocalDataSource(prefs);
  });

  group('OnboardingLocalDataSource.hasSeenWelcome', () {
    test('SharedPreferences 沒有存過值時，預設回傳 false', () {
      when(
        () => prefs.getBool(AppPreferenceKeys.hasSeenWelcome),
      ).thenReturn(null);
      expect(dataSource.hasSeenWelcome(), isFalse);
    });

    test('回傳 SharedPreferences 實際存的值', () {
      when(
        () => prefs.getBool(AppPreferenceKeys.hasSeenWelcome),
      ).thenReturn(true);
      expect(dataSource.hasSeenWelcome(), isTrue);
    });
  });

  group('OnboardingLocalDataSource.markWelcomeAsSeen', () {
    test('用正確的 key 把值寫入 true', () async {
      when(
        () => prefs.setBool(AppPreferenceKeys.hasSeenWelcome, any()),
      ).thenAnswer((_) async {});
      await dataSource.markWelcomeAsSeen();
      verify(
        () => prefs.setBool(AppPreferenceKeys.hasSeenWelcome, true),
      ).called(1);
    });
  });
}
