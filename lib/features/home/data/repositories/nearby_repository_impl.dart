import 'package:flutter_travel_audio_guide/features/home/data/datasources/nearby_local_data_source.dart';
import 'package:flutter_travel_audio_guide/features/home/domain/repositories/nearby_repository.dart';

class NearbyRepositoryImpl implements NearbyRepository {
  const NearbyRepositoryImpl(this._localDataSource);

  final NearbyLocalDataSource _localDataSource;

  @override
  bool isNearbyEnabled() => _localDataSource.getNearbyEnabled();

  @override
  Future<void> setNearbyEnabled(bool value) =>
      _localDataSource.setNearbyEnabled(value);
}
