import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/preferences/shared_preferences_provider.dart';
import 'package:flutter_travel_audio_guide/features/home/data/datasources/nearby_local_data_source.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferencesWithCache extends Mock
    implements SharedPreferencesWithCache {}

void main() {
  late MockSharedPreferencesWithCache prefs;
  late NearbyLocalDataSource dataSource;

  setUp(() {
    prefs = MockSharedPreferencesWithCache();
    dataSource = NearbyLocalDataSource(prefs);
  });

  group('NearbyLocalDataSource.getNearbyEnabled', () {
    test('SharedPreferences 沒有存過值時，預設回傳 false', () {
      when(
        () => prefs.getBool(AppPreferenceKeys.nearbyEnabled),
      ).thenReturn(null);
      expect(dataSource.getNearbyEnabled(), isFalse);
    });

    test('回傳 SharedPreferences 實際存的值', () {
      when(
        () => prefs.getBool(AppPreferenceKeys.nearbyEnabled),
      ).thenReturn(true);
      expect(dataSource.getNearbyEnabled(), isTrue);
    });
  });

  group('NearbyLocalDataSource.setNearbyEnabled', () {
    test('用正確的 key 寫入 SharedPreferences', () async {
      when(
        () => prefs.setBool(AppPreferenceKeys.nearbyEnabled, any()),
      ).thenAnswer((_) async {});
      await dataSource.setNearbyEnabled(true);
      verify(
        () => prefs.setBool(AppPreferenceKeys.nearbyEnabled, true),
      ).called(1);
    });
  });
}
