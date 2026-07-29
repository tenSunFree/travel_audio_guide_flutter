import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/daos/attraction_dao.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/nearby/nearby_models.dart';
import 'package:flutter_travel_audio_guide/core/sync/app_sync_service.dart';
import 'package:flutter_travel_audio_guide/core/sync/sync_providers.dart';
import 'package:flutter_travel_audio_guide/features/attraction/di/attraction_providers.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/enums/attraction_sort_filter_enums.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockAttractionDao extends Mock implements AttractionDao {}

class MockAppSyncService extends Mock implements AppSyncService {}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Attraction _buildAttraction({
  int id = 1,
  String name = '景點',
  String distric = '',
}) {
  return Attraction(
    id: id,
    name: name,
    introduction: '',
    openTime: '',
    distric: distric,
    address: '',
    tel: '',
    officialSite: '',
    facebook: '',
    ticket: '',
    remind: '',
    modified: '2026-01-01',
    url: '',
    categories: const [],
    targets: const [],
    friendlies: const [],
    images: const [],
  );
}

void main() {
  late MockAppDatabase db;
  late MockAttractionDao attractionDao;
  late MockAppSyncService syncService;
  late StreamController<List<Attraction>> attractionStream;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(SyncTarget.attractions);
  });

  setUp(() {
    db = MockAppDatabase();
    attractionDao = MockAttractionDao();
    syncService = MockAppSyncService();
    attractionStream = StreamController<List<Attraction>>.broadcast();
    when(() => db.attractionDao).thenReturn(attractionDao);
    when(
      () => attractionDao.watchAll(),
    ).thenAnswer((_) => attractionStream.stream);
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
    await attractionStream.close();
  });

  group('AttractionListController', () {
    test('初始狀態為預設值，建立時會嘗試背景同步並在完成後把 isSyncing 設為 false', () async {
      final state = container.read(attractionListControllerProvider);
      expect(state.allItems, isEmpty);
      expect(state.isLoading, isFalse);
      await _flush();
      verify(() => syncService.syncAllIfNeeded()).called(1);
      expect(
        container.read(attractionListControllerProvider).isSyncing,
        isFalse,
      );
    });

    test('DB stream 發出資料時，會依目前篩選條件計算 items 並更新 total', () async {
      container.read(attractionListControllerProvider);
      attractionStream.add([
        _buildAttraction(id: 1, name: 'B景點'),
        _buildAttraction(id: 2, name: 'A景點'),
      ]);
      await _flush();
      final state = container.read(attractionListControllerProvider);
      expect(state.total, 2);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      // Default sorting apiOrder, maintain the original order
      expect(state.items.map((a) => a.name), ['B景點', 'A景點']);
    });

    test('refresh / loadInitial 成功時會清除 errorMessage 並結束 loading', () async {
      final notifier = container.read(
        attractionListControllerProvider.notifier,
      );
      await notifier.loadInitial();
      final state = container.read(attractionListControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      verify(() => syncService.forceSync(SyncTarget.attractions)).called(1);
    });

    test('refresh 失敗時會設定 errorMessage', () async {
      when(() => syncService.forceSync(any())).thenThrow(Exception('連線失敗'));
      final notifier = container.read(
        attractionListControllerProvider.notifier,
      );
      await notifier.refresh();
      final state = container.read(attractionListControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
    });

    test('applySortFilter 會更新篩選條件並重新計算 items', () async {
      final notifier = container.read(
        attractionListControllerProvider.notifier,
      );
      attractionStream.add([
        _buildAttraction(id: 1, name: '信義景點', distric: '信義區'),
        _buildAttraction(id: 2, name: '士林景點', distric: '士林區'),
      ]);
      await _flush();
      notifier.applySortFilter(
        sortOrder: AttractionSortOrder.nameAZ,
        categoryIds: const {},
        distric: '信義區',
        targets: const {},
        facilities: const {},
      );
      final state = container.read(attractionListControllerProvider);
      expect(state.distric, '信義區');
      expect(state.sortOrder, AttractionSortOrder.nameAZ);
      expect(state.items.map((a) => a.name), ['信義景點']);
    });

    test(
      'applyHomeEntryFilter 會套用首頁帶入的 openNowOnly / timeSlotFilter',
      () async {
        final notifier = container.read(
          attractionListControllerProvider.notifier,
        );
        notifier.applyHomeEntryFilter(
          openNowOnly: true,
          timeSlotFilter: AttractionTimeSlotFilter.morning,
        );
        final state = container.read(attractionListControllerProvider);
        expect(state.openNowOnly, isTrue);
        expect(state.timeSlotFilter, AttractionTimeSlotFilter.morning);
      },
    );

    test('resetFilter 會把所有篩選條件還原成預設值', () async {
      final notifier = container.read(
        attractionListControllerProvider.notifier,
      );
      notifier.applySortFilter(
        sortOrder: AttractionSortOrder.nameAZ,
        categoryIds: const {1, 2},
        distric: '信義區',
        targets: const {},
        facilities: const {},
        openNowOnly: true,
        timeSlotFilter: AttractionTimeSlotFilter.night,
        distanceFilter: DistanceFilter.km1,
      );
      expect(
        container.read(attractionListControllerProvider).isDefaultFilter,
        isFalse,
      );
      notifier.resetFilter();
      expect(
        container.read(attractionListControllerProvider).isDefaultFilter,
        isTrue,
      );
    });

    test('applyLocation 會更新使用者座標', () async {
      final notifier = container.read(
        attractionListControllerProvider.notifier,
      );
      notifier.applyLocation(25.0330, 121.5654);
      final state = container.read(attractionListControllerProvider);
      expect(state.userLat, 25.0330);
      expect(state.userLng, 121.5654);
    });
  });
}
