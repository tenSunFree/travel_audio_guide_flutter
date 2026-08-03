import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/daos/activity_dao.dart';
import 'package:flutter_travel_audio_guide/core/database/daos/attraction_dao.dart';
import 'package:flutter_travel_audio_guide/core/database/daos/audio_guide_dao.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/nearby/location_controller.dart';
import 'package:flutter_travel_audio_guide/core/nearby/nearby_models.dart';
import 'package:flutter_travel_audio_guide/core/sync/app_sync_service.dart';
import 'package:flutter_travel_audio_guide/core/sync/sync_providers.dart';
import 'package:flutter_travel_audio_guide/features/activity/di/activity_providers.dart';
import 'package:flutter_travel_audio_guide/features/attraction/di/attraction_providers.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/controllers/audio_guide_list_controller.dart';
import 'package:flutter_travel_audio_guide/features/home/di/home_providers.dart';
import 'package:flutter_travel_audio_guide/features/home/di/nearby_providers.dart';
import 'package:flutter_travel_audio_guide/features/home/domain/repositories/nearby_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockAttractionDao extends Mock implements AttractionDao {}

class MockActivityDao extends Mock implements ActivityDao {}

class MockAudioGuideDao extends Mock implements AudioGuideDao {}

class MockAppSyncService extends Mock implements AppSyncService {}

class MockNearbyRepository extends Mock implements NearbyRepository {}

/// Use the real LocationController as a base (preserves StateNotifier's state
/// broadcasting), but override getCurrentLocation() to avoid interacting with
/// native plugins such as Geolocator.
class FakeLocationController extends LocationController {
  Object? errorOnGetCurrentLocation;
  GeoPoint? Function()? onGetCurrentLocation;

  void setPermission(NearbyPermissionState permission) {
    state = state.copyWith(permissionState: permission);
  }

  @override
  Future<GeoPoint?> getCurrentLocation({bool forceRefresh = false}) async {
    if (errorOnGetCurrentLocation != null) {
      throw errorOnGetCurrentLocation!;
    }
    return onGetCurrentLocation?.call();
  }
}

// Coordinate helper: move northwards. For lat-only displacements the
// Haversine formula is an exact solution
// distance = earthRadius * deltaLatitude(radians), which is identical to the
// formula used by NearbyUtils.distanceMeters. There is no approximation error
// so boundary tests won't be flaky.
const _earthRadius = 6371000.0;
const _baseLat = 25.0330;
const _baseLng = 121.5654;

double _latAtDistance(double meters) {
  final dLatRad = meters / _earthRadius;
  return _baseLat + dLatRad * 180 / math.pi;
}

Attraction _buildAttraction({
  required int id,
  String name = '景點',
  double? distanceMeters,
}) {
  return Attraction(
    id: id,
    name: name,
    introduction: '',
    openTime: '',
    distric: '',
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
    nlat: distanceMeters == null ? null : _latAtDistance(distanceMeters),
    elong: distanceMeters == null ? null : _baseLng,
  );
}

AudioGuide _buildAudioGuide({
  required int id,
  String title = '導覽',
  int? matchedAttractionId,
}) {
  return AudioGuide(
    id: id,
    title: title,
    url: '',
    modified: '2026-01-01',
    isDownloaded: false,
    matchedAttractionId: matchedAttractionId,
  );
}

void main() {
  late MockAppDatabase db;
  late MockAttractionDao attractionDao;
  late MockActivityDao activityDao;
  late MockAudioGuideDao audioGuideDao;
  late MockAppSyncService syncService;
  late MockNearbyRepository nearbyRepository;
  late FakeLocationController locationController;
  late ProviderContainer container;
  var attractionFixtures = const <Attraction>[];
  var audioGuideFixtures = const <AudioGuide>[];

  setUpAll(() {
    registerFallbackValue(SyncTarget.attractions);
  });

  setUp(() {
    db = MockAppDatabase();
    attractionDao = MockAttractionDao();
    activityDao = MockActivityDao();
    audioGuideDao = MockAudioGuideDao();
    syncService = MockAppSyncService();
    nearbyRepository = MockNearbyRepository();
    locationController = FakeLocationController();
    attractionFixtures = const [];
    audioGuideFixtures = const [];
    when(() => db.attractionDao).thenReturn(attractionDao);
    when(() => db.activityDao).thenReturn(activityDao);
    when(() => db.audioGuideDao).thenReturn(audioGuideDao);
    // Use Stream.value(...) instead of a shared broadcast StreamController:
    // NearbyHomeController._refresh() reads a snapshot with .first, while
    // Attraction/Activity/AudioGuideListController._init() uses .listen() to
    // subscribe long-term. If both consumers share a broadcast stream, timing
    // differences can make .first never receive a value. Returning a new
    // Stream.value on each call ensures both consumers get the snapshot
    // immediately and keeps tests stable.
    when(
      () => attractionDao.watchAll(),
    ).thenAnswer((_) => Stream.value(attractionFixtures));
    when(
      () => activityDao.watchAll(),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => audioGuideDao.watchAll(),
    ).thenAnswer((_) => Stream.value(audioGuideFixtures));
    when(() => syncService.syncAllIfNeeded()).thenAnswer((_) async {});
    when(() => syncService.forceSync(any())).thenAnswer((_) async {});
    // By default, make setNearbyEnabled return a successful Future<void>.
    // Individual tests that need to verify call counts or parameters can use
    // verify() directly without re-mocking.
    when(
      () => nearbyRepository.setNearbyEnabled(any()),
    ).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appSyncServiceProvider.overrideWithValue(syncService),
        nearbyRepositoryProvider.overrideWithValue(nearbyRepository),
        locationControllerProvider.overrideWith((ref) => locationController),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> flush() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('NearbyHomeController.restoreIfPreviouslyEnabled', () {
    test('先前未曾允許定位時，不會嘗試取得位置', () async {
      when(() => nearbyRepository.isNearbyEnabled()).thenReturn(false);
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.restoreIfPreviouslyEnabled();
      expect(container.read(nearbyHomeControllerProvider).hasLocation, isFalse);
      verifyNever(() => nearbyRepository.setNearbyEnabled(any()));
    });

    test('曾經允許定位，但目前拿不到座標時，會清除授權狀態', () async {
      when(() => nearbyRepository.isNearbyEnabled()).thenReturn(true);
      when(
        () => nearbyRepository.setNearbyEnabled(any()),
      ).thenAnswer((_) async {});
      locationController.onGetCurrentLocation = () => null;
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.restoreIfPreviouslyEnabled();
      final state = container.read(nearbyHomeControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.hasLocation, isFalse);
      verify(() => nearbyRepository.setNearbyEnabled(false)).called(1);
    });

    test('曾經允許定位且成功取得座標時，會完整刷新最近景點/導覽清單', () async {
      attractionFixtures = [
        _buildAttraction(id: 1, name: '近景點', distanceMeters: 500),
        _buildAttraction(id: 2, name: '遠景點', distanceMeters: 8000),
      ];
      when(() => nearbyRepository.isNearbyEnabled()).thenReturn(true);
      locationController.onGetCurrentLocation = () =>
          const GeoPoint(latitude: _baseLat, longitude: _baseLng);
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.restoreIfPreviouslyEnabled();
      await flush();
      final state = container.read(nearbyHomeControllerProvider);
      expect(state.hasLocation, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.nearbyAttractions.map((a) => a.name), ['近景點']);
    });

    test('重複呼叫第二次不會再嘗試取得位置（避免重複觸發）', () async {
      when(() => nearbyRepository.isNearbyEnabled()).thenReturn(false);
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.restoreIfPreviouslyEnabled();
      await notifier.restoreIfPreviouslyEnabled();
      verify(() => nearbyRepository.isNearbyEnabled()).called(1);
    });
  });

  group('NearbyHomeController.enableNearby', () {
    test('使用者拒絕定位（取得座標為 null）時，只結束 loading，不記住授權', () async {
      locationController.onGetCurrentLocation = () => null;
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.enableNearby();
      final state = container.read(nearbyHomeControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.hasLocation, isFalse);
      verifyNever(() => nearbyRepository.setNearbyEnabled(any()));
    });

    test('成功取得座標時，記住授權並刷新資料', () async {
      attractionFixtures = [
        _buildAttraction(id: 1, name: '近景點', distanceMeters: 500),
      ];
      when(
        () => nearbyRepository.setNearbyEnabled(any()),
      ).thenAnswer((_) async {});
      locationController.onGetCurrentLocation = () =>
          const GeoPoint(latitude: _baseLat, longitude: _baseLng);
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.enableNearby();
      await flush();
      final state = container.read(nearbyHomeControllerProvider);
      expect(state.hasLocation, isTrue);
      expect(state.nearbyAttractions.map((a) => a.name), ['近景點']);
      verify(() => nearbyRepository.setNearbyEnabled(true)).called(1);
    });

    test('取得座標過程拋出例外時，會結束 loading 而不會讓例外往外拋', () async {
      locationController.errorOnGetCurrentLocation = Exception('定位失敗');
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.enableNearby();
      expect(container.read(nearbyHomeControllerProvider).isLoading, isFalse);
    });

    test(
      '成功後會把使用者座標同步套用到 Attraction/Activity/AudioGuide 三個列表 controller',
      () async {
        when(
          () => nearbyRepository.setNearbyEnabled(any()),
        ).thenAnswer((_) async {});
        locationController.onGetCurrentLocation = () =>
            const GeoPoint(latitude: _baseLat, longitude: _baseLng);
        final notifier = container.read(nearbyHomeControllerProvider.notifier);
        await notifier.enableNearby();
        await flush();
        expect(
          container.read(attractionListControllerProvider).userLat,
          _baseLat,
        );
        expect(
          container.read(attractionListControllerProvider).userLng,
          _baseLng,
        );
        expect(
          container.read(activityListControllerProvider).userLat,
          _baseLat,
        );
        expect(
          container.read(activityListControllerProvider).userLng,
          _baseLng,
        );
        expect(
          container.read(audioGuideListControllerProvider).userLat,
          _baseLat,
        );
        expect(
          container.read(audioGuideListControllerProvider).userLng,
          _baseLng,
        );
      },
    );
  });

  group('NearbyHomeController.refresh', () {
    test('尚未取得定位權限時，直接return，不會呼叫 getCurrentLocation', () async {
      locationController.setPermission(NearbyPermissionState.denied);
      var called = false;
      locationController.onGetCurrentLocation = () {
        called = true;
        return null;
      };
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.refresh();
      expect(called, isFalse);
    });

    test('已授權時會強制刷新座標並更新最近清單', () async {
      attractionFixtures = [
        _buildAttraction(id: 1, name: '近景點', distanceMeters: 1500),
      ];
      locationController
        ..setPermission(NearbyPermissionState.granted)
        ..onGetCurrentLocation = () =>
            const GeoPoint(latitude: _baseLat, longitude: _baseLng);
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.refresh();
      await flush();
      final state = container.read(nearbyHomeControllerProvider);
      expect(state.hasLocation, isTrue);
      expect(state.nearbyAttractions.map((a) => a.name), ['近景點']);
    });

    test('過程發生例外時只記錄錯誤，不會讓 state 陷入 loading 卡死', () async {
      locationController
        ..setPermission(NearbyPermissionState.granted)
        ..errorOnGetCurrentLocation = Exception('刷新失敗');
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      final before = container.read(nearbyHomeControllerProvider);
      await notifier.refresh();
      final after = container.read(nearbyHomeControllerProvider);
      expect(after.isLoading, before.isLoading);
    });
  });

  group('NearbyHomeController — 距離分桶邏輯（3km → 5km → 10km 依序退回）', () {
    test('3km 內有結果時，直接採用 3km 桶，依距離升冪排序', () async {
      attractionFixtures = [
        _buildAttraction(id: 1, name: 'B', distanceMeters: 2900),
        _buildAttraction(id: 2, name: 'A', distanceMeters: 500),
        _buildAttraction(id: 3, name: '太遠', distanceMeters: 8000),
      ];
      locationController.onGetCurrentLocation = () =>
          const GeoPoint(latitude: _baseLat, longitude: _baseLng);
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.enableNearby();
      await flush();
      final names = container
          .read(nearbyHomeControllerProvider)
          .nearbyAttractions
          .map((a) => a.name)
          .toList();
      expect(names, ['A', 'B']);
    });

    test('3km 內沒有結果時，退回 5km 桶', () async {
      attractionFixtures = [
        _buildAttraction(id: 1, name: '4km處', distanceMeters: 4000),
      ];
      locationController.onGetCurrentLocation = () =>
          const GeoPoint(latitude: _baseLat, longitude: _baseLng);
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.enableNearby();
      await flush();
      expect(
        container
            .read(nearbyHomeControllerProvider)
            .nearbyAttractions
            .map((a) => a.name),
        ['4km處'],
      );
    });

    test('3km、5km 都沒有結果時，退回 10km 桶', () async {
      attractionFixtures = [
        _buildAttraction(id: 1, name: '8km處', distanceMeters: 8000),
      ];
      locationController.onGetCurrentLocation = () =>
          const GeoPoint(latitude: _baseLat, longitude: _baseLng);
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.enableNearby();
      await flush();
      expect(
        container
            .read(nearbyHomeControllerProvider)
            .nearbyAttractions
            .map((a) => a.name),
        ['8km處'],
      );
    });

    test('10km 內完全沒有結果、或座標無效時，回傳空清單', () async {
      attractionFixtures = [
        _buildAttraction(id: 1, name: '太遠', distanceMeters: 20000),
        _buildAttraction(id: 2, name: '無座標'), // nlat/elong are both null
      ];
      locationController.onGetCurrentLocation = () =>
          const GeoPoint(latitude: _baseLat, longitude: _baseLng);
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.enableNearby();
      await flush();
      expect(
        container.read(nearbyHomeControllerProvider).nearbyAttractions,
        isEmpty,
      );
    });

    test('最多只回傳 5 筆，即使符合距離門檻的景點更多', () async {
      attractionFixtures = List.generate(
        8,
        (i) => _buildAttraction(
          id: i + 1,
          name: '景點$i',
          distanceMeters: 100.0 * (i + 1),
        ),
      );
      locationController.onGetCurrentLocation = () =>
          const GeoPoint(latitude: _baseLat, longitude: _baseLng);
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.enableNearby();
      await flush();
      expect(
        container.read(nearbyHomeControllerProvider).nearbyAttractions.length,
        5,
      );
    });
  });

  group('NearbyHomeController — 導覽音檔的最近距離解析', () {
    test('導覽透過 matchedAttractionId 找到對應景點座標才會被視為附近', () async {
      attractionFixtures = [
        _buildAttraction(id: 1, name: '博物館', distanceMeters: 800),
      ];
      audioGuideFixtures = [
        _buildAudioGuide(id: 1, title: '博物館導覽', matchedAttractionId: 1),
        _buildAudioGuide(id: 2, title: '沒有對應景點的導覽'),
        _buildAudioGuide(id: 3, title: '對應景點不存在', matchedAttractionId: 999),
      ];
      locationController.onGetCurrentLocation = () =>
          const GeoPoint(latitude: _baseLat, longitude: _baseLng);
      final notifier = container.read(nearbyHomeControllerProvider.notifier);
      await notifier.enableNearby();
      await flush();
      final titles = container
          .read(nearbyHomeControllerProvider)
          .nearbyAudioGuides
          .map((g) => g.title)
          .toList();
      expect(titles, ['博物館導覽']);
    });
  });
}
