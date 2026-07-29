import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/core/database/daos/activity_dao.dart';
import 'package:flutter_travel_audio_guide/core/database/daos/attraction_dao.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:flutter_travel_audio_guide/features/home/data/repositories/home_repository.dart';
import 'package:flutter_travel_audio_guide/features/home/domain/entities/home_state.dart';

class MockAttractionDao extends Mock implements AttractionDao {}

class MockActivityDao extends Mock implements ActivityDao {}

void main() {
  late MockAttractionDao attractionDao;
  late MockActivityDao activityDao;
  late StreamController<List<Attraction>> attractionController;
  late StreamController<List<Activity>> activityController;
  late HomeRepository repository;

  setUp(() {
    attractionDao = MockAttractionDao();
    activityDao = MockActivityDao();
    // Use a broadcast StreamController to simulate Drift's watchAll().
    // HomeRepository's internal _combineLatest subscribes to both streams
    // synchronously when watchHomeState() is called.
    attractionController = StreamController<List<Attraction>>.broadcast();
    activityController = StreamController<List<Activity>>.broadcast();
    when(
      () => attractionDao.watchAll(),
    ).thenAnswer((_) => attractionController.stream);
    when(
      () => activityDao.watchAll(),
    ).thenAnswer((_) => activityController.stream);

    repository = HomeRepository(
      attractionDao: attractionDao,
      activityDao: activityDao,
    );
  });

  tearDown(() async {
    await attractionController.close();
    await activityController.close();
  });

  Attraction buildAttraction({
    int id = 1,
    String name = '故宮博物院',
    String openTime = '09:00-17:00',
    List<AttractionCategory> categories = const [],
    List<AttractionImage> images = const [],
    double? nlat,
    double? elong,
    String ticket = '',
    String distric = '士林區',
  }) {
    return Attraction(
      id: id,
      name: name,
      introduction: '',
      openTime: openTime,
      distric: distric,
      address: '台北市$distric',
      tel: '',
      officialSite: '',
      facebook: '',
      ticket: ticket,
      remind: '',
      modified: '2026-01-01',
      url: '',
      categories: categories,
      targets: const [],
      friendlies: const [],
      images: images,
      nlat: nlat,
      elong: elong,
    );
  }

  Activity buildActivity({
    int id = 1,
    String title = '台北燈節',
    required String begin,
    required String end,
    String address = '台北市信義區',
    String distric = '信義區',
    String ticket = '',
  }) {
    return Activity(
      id: id,
      title: title,
      description: '',
      begin: begin,
      end: end,
      posted: begin,
      modified: begin,
      url: '',
      address: address,
      distric: distric,
      nlat: '25.03',
      elong: '121.56',
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

  group('HomeRepository.watchHomeState — 基本狀態', () {
    test('景點與活動皆為空清單時，維持 loading 狀態', () async {
      final future = repository
          .watchHomeState(period: HomePeriod.afternoon, isRainyMode: false)
          .first;
      attractionController.add(const []);
      activityController.add(const []);
      final state = await future;
      expect(state.isLoading, isTrue);
      expect(state.heroCard, isNull);
      expect(state.nearbyCards, isEmpty);
      expect(state.activityCards, isEmpty);
      expect(state.availableCards, isEmpty);
    });

    test('名稱為空白字串的景點會被過濾掉，不影響其餘景點', () async {
      final future = repository
          .watchHomeState(period: HomePeriod.afternoon, isRainyMode: false)
          .first;
      attractionController.add([
        buildAttraction(id: 1, name: '   '),
        buildAttraction(id: 2, name: '有效景點'),
      ]);
      activityController.add(const []);
      final state = await future;
      expect(state.isLoading, isFalse);
      expect(state.heroCard?.title, '有效景點');
    });
  });

  group('HomeRepository.watchHomeState — 景點計分與排序', () {
    test('分數最高的景點成為 heroCard，其餘依分數降冪排入 nearbyCards', () async {
      final future = repository
          .watchHomeState(period: HomePeriod.morning, isRainyMode: false)
          .first;
      attractionController.add([
        // Low score: no images, no coordinates, not matching the period
        buildAttraction(
          id: 1,
          name: '普通景點',
          categories: const [],
          nlat: null,
          elong: null,
        ),
        // High score: has images, has coordinates, matches morning period (outdoor/trekking), open all day
        buildAttraction(
          id: 2,
          name: '陽明山步道',
          openTime: '00:00-23:59',
          nlat: 25.15,
          elong: 121.56,
          categories: const [AttractionCategory(id: 1, name: '戶外踏青')],
          images: const [
            AttractionImage(
              src: 'https://example.com/a.png',
              subject: '',
              ext: 'png',
            ),
          ],
        ),
      ]);
      activityController.add(const []);
      final state = await future;
      expect(state.heroCard?.title, '陽明山步道');
      expect(state.nearbyCards.map((c) => c.title), ['普通景點']);
    });

    test('雨天模式下，室內景點加分、戶外景點扣分，會影響最終排序', () async {
      final future = repository
          .watchHomeState(period: HomePeriod.afternoon, isRainyMode: true)
          .first;
      attractionController.add([
        buildAttraction(
          id: 1,
          name: '戶外公園',
          categories: const [AttractionCategory(id: 1, name: '戶外踏青')],
        ),
        buildAttraction(
          id: 2,
          name: '故宮博物院',
          categories: const [AttractionCategory(id: 2, name: '博物館')],
        ),
      ]);
      activityController.add(const []);
      final state = await future;
      // With all other conditions equal, the indoor museum should outrank the outdoor park in rainy mode.
      expect(state.heroCard?.title, '故宮博物院');
    });

    test('reasonText 會優先顯示免費資訊', () async {
      final future = repository
          .watchHomeState(period: HomePeriod.afternoon, isRainyMode: false)
          .first;
      attractionController.add([
        buildAttraction(
          id: 1,
          name: '免費博物館',
          ticket: '免費參觀',
          openTime: '00:00-23:59',
        ),
      ]);
      activityController.add(const []);
      final state = await future;
      expect(state.heroCard?.reasonText, contains('免費參觀'));
    });
  });

  group('HomeRepository.watchHomeState — 活動計分與狀態', () {
    test('begin / end 無法解析日期的活動會被排除', () async {
      final future = repository
          .watchHomeState(period: HomePeriod.afternoon, isRainyMode: false)
          .first;
      attractionController.add(const []);
      activityController.add([
        buildActivity(id: 1, title: '日期異常活動', begin: '不是日期', end: '也不是'),
      ]);
      final state = await future;
      expect(state.activityCards, isEmpty);
    });

    test('進行中的活動標記為「進行中」，尚未開始的活動標記為「即將登場」', () async {
      final now = DateTime.now();
      final future = repository
          .watchHomeState(period: HomePeriod.afternoon, isRainyMode: false)
          .first;
      attractionController.add(const []);
      activityController.add([
        buildActivity(
          id: 1,
          title: '進行中活動',
          begin: now.subtract(const Duration(days: 1)).toIso8601String(),
          end: now.add(const Duration(days: 1)).toIso8601String(),
          ticket: '免費',
        ),
        buildActivity(
          id: 2,
          title: '即將登場活動',
          begin: now.add(const Duration(days: 3)).toIso8601String(),
          end: now.add(const Duration(days: 10)).toIso8601String(),
          ticket: '免費',
        ),
      ]);
      final state = await future;
      final ongoing = state.activityCards.firstWhere((c) => c.title == '進行中活動');
      expect(ongoing.badgeText, '進行中');
      final comingSoon = state.activityCards.firstWhere(
        (c) => c.title == '即將登場活動',
      );
      expect(comingSoon.badgeText, '即將登場');
    });

    test('票價含「免費」字樣時 reasonText 顯示「免費」', () async {
      final now = DateTime.now();
      final future = repository
          .watchHomeState(period: HomePeriod.afternoon, isRainyMode: false)
          .first;
      attractionController.add(const []);
      activityController.add([
        buildActivity(
          id: 1,
          begin: now.subtract(const Duration(hours: 1)).toIso8601String(),
          end: now.add(const Duration(days: 1)).toIso8601String(),
          ticket: '免費入場',
        ),
      ]);
      final state = await future;
      expect(state.activityCards.single.reasonText, '免費');
    });

    test('API 常見的「yyyy/MM/dd HH:mm:ss +08:00」格式也能正確解析', () async {
      final now = DateTime.now();
      final begin = now.subtract(const Duration(hours: 2));
      final end = now.add(const Duration(days: 2));
      String toApiFormat(DateTime d) {
        String two(int n) => n.toString().padLeft(2, '0');
        return '${d.year}/${two(d.month)}/${two(d.day)} '
            '${two(d.hour)}:${two(d.minute)}:${two(d.second)} +08:00';
      }

      final future = repository
          .watchHomeState(period: HomePeriod.afternoon, isRainyMode: false)
          .first;
      attractionController.add(const []);
      activityController.add([
        buildActivity(
          id: 1,
          title: 'API格式活動',
          begin: toApiFormat(begin),
          end: toApiFormat(end),
          ticket: '免費',
        ),
      ]);
      final state = await future;
      expect(state.activityCards, isNotEmpty);
      expect(state.activityCards.single.title, 'API格式活動');
      expect(state.activityCards.single.badgeText, '進行中');
    });
  });
}
