import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/sync/app_sync_service.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/models/activity_model.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/models/activity_page_model.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/datasources/attraction_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/models/attraction_model.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/models/attraction_page_model.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/audio_guide_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/models/audio_guide_model.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/models/audio_guide_page_model.dart';

class MockAttractionRemoteDataSource extends Mock
    implements AttractionRemoteDataSource {}

class MockAudioGuideRemoteDataSource extends Mock
    implements AudioGuideRemoteDataSource {}

class MockActivityRemoteDataSource extends Mock
    implements ActivityRemoteDataSource {}

// These constants mirror the private static keys in
// lib/core/sync/app_sync_service.dart.
// They are implementation details but stable; copy them here to verify
// that sync_meta entries are written.
const _attractionKey = 'sync_attractions';
const _audioGuideKey = 'sync_audio_guides';
const _activityKey = 'sync_activities';

AttractionModel _buildAttractionModel({
  int id = 1,
  String name = '景點',
  String modified = '2026-01-01',
}) {
  return AttractionModel(id: id, name: name, modified: modified);
}

ActivityModel _buildActivityModel({
  int id = 1,
  String title = '活動',
  String modified = '2026-01-01',
}) {
  return ActivityModel(id: id, title: title, modified: modified);
}

AudioGuideModel _buildAudioGuideModel({
  required int id,
  String title = '導覽',
  String modified = '2026-01-01',
}) {
  return AudioGuideModel(id: id, title: title, modified: modified);
}

void main() {
  late AppDatabase db;
  late MockAttractionRemoteDataSource attractionRemote;
  late MockAudioGuideRemoteDataSource audioGuideRemote;
  late MockActivityRemoteDataSource activityRemote;
  late AppSyncService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    attractionRemote = MockAttractionRemoteDataSource();
    audioGuideRemote = MockAudioGuideRemoteDataSource();
    activityRemote = MockActivityRemoteDataSource();
    service = AppSyncService(
      db: db,
      attractionRemote: attractionRemote,
      audioGuideRemote: audioGuideRemote,
      activityRemote: activityRemote,
    );
    // By default the three remote sources return empty lists. Individual
    // tests will override these as needed.
    when(
      () => attractionRemote.getAttractions(
        lang: any(named: 'lang'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) async => const AttractionPageModel(total: 0, page: 1, data: []),
    );
    when(
      () => audioGuideRemote.getAudioGuides(
        lang: any(named: 'lang'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) async => const AudioGuidePageModel(total: 0, page: 1, data: []),
    );
    when(
      () => activityRemote.getActivities(
        lang: any(named: 'lang'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) async => const ActivityPageModel(total: 0, page: 1, data: []),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AppSyncService.syncAllIfNeeded — TTL 行為', () {
    test('第一次呼叫（尚無同步紀錄）會同步全部三個目標，並寫入 sync_meta', () async {
      await service.syncAllIfNeeded();
      verify(
        () => attractionRemote.getAttractions(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      ).called(1);
      verify(
        () => audioGuideRemote.getAudioGuides(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      ).called(1);
      verify(
        () => activityRemote.getActivities(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      ).called(1);
      expect(await db.syncMetaDao.getLastSyncedAt(_attractionKey), isNotNull);
      expect(await db.syncMetaDao.getLastSyncedAt(_audioGuideKey), isNotNull);
      expect(await db.syncMetaDao.getLastSyncedAt(_activityKey), isNotNull);
    });

    test('TTL 尚未過期時，第二次呼叫不會再打 API', () async {
      await service.syncAllIfNeeded();
      await service.syncAllIfNeeded();
      verify(
        () => attractionRemote.getAttractions(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      ).called(1);
    });

    test('單一目標同步失敗時，只有那個目標不會寫入 sync_meta，其餘目標仍正常完成', () async {
      when(
        () => attractionRemote.getAttractions(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      ).thenThrow(Exception('network error'));
      await service.syncAllIfNeeded();
      expect(await db.syncMetaDao.getLastSyncedAt(_attractionKey), isNull);
      expect(await db.syncMetaDao.getLastSyncedAt(_audioGuideKey), isNotNull);
      expect(await db.syncMetaDao.getLastSyncedAt(_activityKey), isNotNull);
    });
  });

  group('AppSyncService.forceSync', () {
    test('只會同步指定的目標，不會動到其他兩個', () async {
      await service.forceSync(SyncTarget.attractions);
      verify(
        () => attractionRemote.getAttractions(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      ).called(1);
      verifyNever(
        () => audioGuideRemote.getAudioGuides(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      );
      verifyNever(
        () => activityRemote.getActivities(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      );
    });

    test('會略過 TTL 檢查，連續呼叫兩次一樣都會打 API', () async {
      await service.forceSync(SyncTarget.activities);
      await service.forceSync(SyncTarget.activities);
      verify(
        () => activityRemote.getActivities(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      ).called(2);
    });
  });

  group('AppSyncService — 差異更新（只更新 modified 有變的資料）', () {
    test('modified 沒變的景點不會被覆蓋；modified 有變的才會更新', () async {
      // Insert initial local records first
      await db.attractionDao.upsertAll([
        _buildAttractionModel(id: 1, name: '原始名稱A', modified: '2026-01-01'),
        _buildAttractionModel(id: 2, name: '原始名稱B', modified: '2026-01-01'),
      ]);
      // Remote response: #1 has same modified (should not overwrite),
      // #2 has different modified (should update)
      when(
        () =>
            attractionRemote.getAttractions(lang: any(named: 'lang'), page: 1),
      ).thenAnswer(
        (_) async => AttractionPageModel(
          total: 2,
          page: 1,
          data: [
            _buildAttractionModel(
              id: 1,
              name: '被改壞的名稱A',
              modified: '2026-01-01',
            ),
            _buildAttractionModel(
              id: 2,
              name: '更新後的名稱B',
              modified: '2026-02-01',
            ),
          ],
        ),
      );
      await service.forceSync(SyncTarget.attractions);
      final all = await db.attractionDao.getAll();
      final byId = {for (final r in all) r.id: r};
      expect(byId[1]!.name, '原始名稱A'); // not overwritten
      expect(byId[2]!.name, '更新後的名稱B'); // updated
    });

    test('全新的景點（本地沒有）一律視為變更，會被寫入', () async {
      when(
        () =>
            attractionRemote.getAttractions(lang: any(named: 'lang'), page: 1),
      ).thenAnswer(
        (_) async => AttractionPageModel(
          total: 1,
          page: 1,
          data: [_buildAttractionModel(id: 99, name: '全新景點')],
        ),
      );
      await service.forceSync(SyncTarget.attractions);
      final all = await db.attractionDao.getAll();
      expect(all.map((r) => r.id), contains(99));
    });
  });

  group('AppSyncService — AudioGuide 與景點的名稱比對', () {
    test('導覽標題與景點名稱（正規化後）相符時，會寫入 matchedAttractionId，且保留原本的下載狀態', () async {
      // Prepare an attraction first
      await db.attractionDao.upsertAll([
        _buildAttractionModel(id: 1, name: '故宮博物院'),
      ]);
      // Prepare an existing downloaded audio guide record
      final oldModel = _buildAudioGuideModel(
        id: 1,
        title: '舊標題',
        modified: '2026-01-01',
      );
      await db.audioGuideDao.upsertAll([
        db.audioGuideDao.toCompanion(
          oldModel,
          matchedAttractionId: null,
          isDownloaded: true,
          localFilePath: '/tmp/old.mp3',
        ),
      ]);
      // Remote returns a new version: title matches the attraction name,
      // modified changed -> should be updated
      when(
        () =>
            audioGuideRemote.getAudioGuides(lang: any(named: 'lang'), page: 1),
      ).thenAnswer(
        (_) async => AudioGuidePageModel(
          total: 1,
          page: 1,
          data: [
            _buildAudioGuideModel(
              id: 1,
              title: '故宮博物院',
              modified: '2026-02-01',
            ),
          ],
        ),
      );
      await service.forceSync(SyncTarget.audioGuides);
      final updated = await db.audioGuideDao.findById(1);
      expect(updated, isNotNull);
      expect(updated!.title, '故宮博物院');
      expect(updated.matchedAttractionId, 1);
      expect(
        updated.isDownloaded,
        isTrue,
      ); // retains the previously downloaded status
      expect(
        updated.localFilePath,
        '/tmp/old.mp3',
      ); // retains the previous file path
    });

    test('導覽標題找不到對應景點時，matchedAttractionId 為 null', () async {
      await db.attractionDao.upsertAll([
        _buildAttractionModel(id: 1, name: '故宮博物院'),
      ]);
      when(
        () =>
            audioGuideRemote.getAudioGuides(lang: any(named: 'lang'), page: 1),
      ).thenAnswer(
        (_) async => AudioGuidePageModel(
          total: 1,
          page: 1,
          data: [_buildAudioGuideModel(id: 2, title: '完全對不上的標題')],
        ),
      );
      await service.forceSync(SyncTarget.audioGuides);
      final result = await db.audioGuideDao.findById(2);
      expect(result!.matchedAttractionId, isNull);
    });
  });

  group('AppSyncService — 分頁抓取', () {
    test('會持續翻頁直到抓滿 total 筆數為止', () async {
      when(
        () => activityRemote.getActivities(lang: any(named: 'lang'), page: 1),
      ).thenAnswer(
        (_) async => ActivityPageModel(
          total: 3,
          page: 1,
          data: [
            _buildActivityModel(id: 1, title: 'A'),
            _buildActivityModel(id: 2, title: 'B'),
          ],
        ),
      );
      when(
        () => activityRemote.getActivities(lang: any(named: 'lang'), page: 2),
      ).thenAnswer(
        (_) async => ActivityPageModel(
          total: 3,
          page: 2,
          data: [_buildActivityModel(id: 3, title: 'C')],
        ),
      );
      await service.forceSync(SyncTarget.activities);
      final all = await db.activityDao.getAll();
      expect(all.map((r) => r.id).toSet(), {1, 2, 3});
      verify(
        () => activityRemote.getActivities(lang: any(named: 'lang'), page: 2),
      ).called(1);
    });

    test('該頁資料為空時立刻停止翻頁', () async {
      when(
        () => activityRemote.getActivities(lang: any(named: 'lang'), page: 1),
      ).thenAnswer(
        (_) async => const ActivityPageModel(total: 5, page: 1, data: []),
      );
      await service.forceSync(SyncTarget.activities);
      final all = await db.activityDao.getAll();
      expect(all, isEmpty);
      verifyNever(
        () => activityRemote.getActivities(lang: any(named: 'lang'), page: 2),
      );
    });
  });
}
