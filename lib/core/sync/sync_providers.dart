import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/network/network_providers.dart';
import 'package:flutter_travel_audio_guide/core/sync/app_sync_service.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/datasources/attraction_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/audio_guide_remote_data_source.dart';

final appSyncServiceProvider = Provider<AppSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return AppSyncService(
    db: db,
    attractionRemote: AttractionRemoteDataSource(dio),
    audioGuideRemote: AudioGuideRemoteDataSource(dio),
    activityRemote: ActivityRemoteDataSource(dio),
  );
});
