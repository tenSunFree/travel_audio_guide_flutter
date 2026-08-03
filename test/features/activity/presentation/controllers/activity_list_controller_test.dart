import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/daos/activity_dao.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/nearby/nearby_models.dart';
import 'package:flutter_travel_audio_guide/core/sync/app_sync_service.dart';
import 'package:flutter_travel_audio_guide/core/sync/sync_providers.dart';
import 'package:flutter_travel_audio_guide/features/activity/di/activity_providers.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity.dart';
import 'package:flutter_travel_audio_guide/features/activity/presentation/enums/activity_sort_filter_enums.dart';
import 'package:mocktail/mocktail.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockActivityDao extends Mock implements ActivityDao {}

class MockAppSyncService extends Mock implements AppSyncService {}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Activity _buildActivity({
  int id = 1,
  String title = '活動',
  String begin = '2026-01-01',
  String distric = '',
  String ticket = '',
}) {
  return Activity(
    id: id,
    title: title,
    description: '',
    begin: begin,
    end: begin,
    posted: '',
    modified: '',
    url: '',
    address: '',
    distric: distric,
    nlat: '',
    elong: '',
    organizer: '',
    coRganizer: '',
    contact: '',
    tel: '',
    ticket: ticket,
    traffic: '',
    parking: '',
    links: const [],
  );
}

void main() {
  late MockAppDatabase db;
  late MockActivityDao activityDao;
  late MockAppSyncService syncService;
  late StreamController<List<Activity>> activityStream;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(SyncTarget.activities);
  });

  setUp(() {
    db = MockAppDatabase();
    activityDao = MockActivityDao();
    syncService = MockAppSyncService();
    activityStream = StreamController<List<Activity>>.broadcast();
    when(() => db.activityDao).thenReturn(activityDao);
    when(() => activityDao.watchAll()).thenAnswer((_) => activityStream.stream);
    when(() => syncService.syncAllIfNeeded()).thenAnswer((_) async {});
    when(() => syncService.forceSync(any())).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appSyncServiceProvider.overrideWithValue(syncService),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() async {
    await activityStream.close();
  });

  group('ActivityListController', () {
    test('初始狀態為 initial()，且會在建立時嘗試背景同步', () async {
      final state = container.read(activityListControllerProvider);
      expect(state.allItems, isEmpty);
      expect(state.items, isEmpty);
      expect(state.isInitialLoading, isFalse);
      await _flush();
      verify(() => syncService.syncAllIfNeeded()).called(1);
    });

    test('DB stream 發出資料時，會依目前的排序/篩選條件計算 items 並更新 total', () async {
      container.read(activityListControllerProvider); // 觸發 controller 建立
      activityStream.add([
        _buildActivity(title: 'B活動', begin: '2026-06-01'),
        _buildActivity(id: 2, title: 'A活動'),
      ]);
      await _flush();
      final state = container.read(activityListControllerProvider);
      expect(state.total, 2);
      expect(state.isInitialLoading, isFalse);
      expect(state.errorMessage, isNull);
      // Preset sort beginAsc
      expect(state.items.map((a) => a.title), ['A活動', 'B活動']);
    });

    test('loadInitial 成功時會清除 errorMessage 並結束 loading', () async {
      final notifier = container.read(activityListControllerProvider.notifier);
      await notifier.loadInitial();
      final state = container.read(activityListControllerProvider);
      expect(state.isInitialLoading, isFalse);
      expect(state.errorMessage, isNull);
      verify(() => syncService.forceSync(SyncTarget.activities)).called(1);
    });

    test('loadInitial 失敗時會設定 errorMessage', () async {
      when(() => syncService.forceSync(any())).thenThrow(Exception('網路錯誤'));
      final notifier = container.read(activityListControllerProvider.notifier);
      await notifier.loadInitial();
      final state = container.read(activityListControllerProvider);
      expect(state.isInitialLoading, isFalse);
      expect(state.errorMessage, isNotNull);
    });

    test('applySortFilter 會更新排序/篩選條件並重新計算 items', () async {
      final notifier = container.read(activityListControllerProvider.notifier);
      activityStream.add([
        _buildActivity(title: '免費活動'),
        _buildActivity(id: 2, title: '付費活動', ticket: '100元'),
      ]);
      await _flush();
      notifier.applySortFilter(
        sortOrder: ActivitySortOrder.nameAZ,
        statusFilter: ActivityStatusFilter.all,
        feeFilter: ActivityFeeFilter.free,
        distric: '',
        distanceFilter: DistanceFilter.unlimited,
      );
      final state = container.read(activityListControllerProvider);
      expect(state.feeFilter, ActivityFeeFilter.free);
      expect(state.sortOrder, ActivitySortOrder.nameAZ);
      expect(state.items.map((a) => a.title), ['免費活動']);
    });

    test('resetSortFilter 會把所有篩選條件還原成預設值', () async {
      final notifier = container.read(activityListControllerProvider.notifier)
        ..applySortFilter(
          sortOrder: ActivitySortOrder.nameAZ,
          statusFilter: ActivityStatusFilter.today,
          feeFilter: ActivityFeeFilter.paid,
          distric: '信義區',
          distanceFilter: DistanceFilter.km1,
        );
      expect(
        container.read(activityListControllerProvider).isDefaultFilter,
        isFalse,
      );
      notifier.resetSortFilter();
      expect(
        container.read(activityListControllerProvider).isDefaultFilter,
        isTrue,
      );
    });

    test('applyLocation 會更新使用者座標並套用距離篩選重新計算 items', () async {
      final notifier = container.read(activityListControllerProvider.notifier);
      activityStream.add([_buildActivity(title: '附近活動')]);
      await _flush();
      notifier.applyLocation(25.0330, 121.5654);
      final state = container.read(activityListControllerProvider);
      expect(state.userLat, 25.0330);
      expect(state.userLng, 121.5654);
    });
  });
}
