import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/core/preferences/shared_preferences_provider.dart';
import 'package:flutter_travel_audio_guide/features/home/data/datasources/nearby_local_data_source.dart';
import 'package:flutter_travel_audio_guide/features/home/data/repositories/nearby_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/home/domain/repositories/nearby_repository.dart';

final nearbyLocalDataSourceProvider = Provider<NearbyLocalDataSource>((ref) {
  return NearbyLocalDataSource(ref.watch(sharedPreferencesProvider));
});

final nearbyRepositoryProvider = Provider<NearbyRepository>((ref) {
  return NearbyRepositoryImpl(ref.watch(nearbyLocalDataSourceProvider));
});
