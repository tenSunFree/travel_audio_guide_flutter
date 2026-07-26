import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/preferences/shared_preferences_provider.dart';
import 'package:flutter_travel_audio_guide/features/home/data/datasources/nearby_local_data_source.dart';
import 'package:flutter_travel_audio_guide/features/home/data/repositories/home_repository.dart';
import 'package:flutter_travel_audio_guide/features/home/data/repositories/nearby_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/home/di/home_providers.dart';
import 'package:flutter_travel_audio_guide/features/home/di/nearby_providers.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('homeRepositoryProvider 正確組裝 HomeRepository', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    expect(container.read(homeRepositoryProvider), isA<HomeRepository>());
  });

  test(
    'nearbyLocalDataSourceProvider 與 nearbyRepositoryProvider 正確組裝',
    () async {
      final prefs = await SharedPreferencesWithCache.create(
        cacheOptions: SharedPreferencesWithCacheOptions(
          allowList: AppPreferenceKeys.allowList,
        ),
      );
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(
        container.read(nearbyLocalDataSourceProvider),
        isA<NearbyLocalDataSource>(),
      );
      expect(
        container.read(nearbyRepositoryProvider),
        isA<NearbyRepositoryImpl>(),
      );
    },
  );
}
