import 'package:flutter_travel_audio_guide/core/preferences/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NearbyLocalDataSource {
  const NearbyLocalDataSource(this._prefs);

  final SharedPreferencesWithCache _prefs;

  bool getNearbyEnabled() =>
      _prefs.getBool(AppPreferenceKeys.nearbyEnabled) ?? false;

  Future<void> setNearbyEnabled(bool value) =>
      _prefs.setBool(AppPreferenceKeys.nearbyEnabled, value);
}
