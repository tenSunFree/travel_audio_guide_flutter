import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/nearby/nearby_models.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/controllers/attraction_list_controller.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/enums/attraction_sort_filter_enums.dart';

void main() {
  Attraction buildAttraction({
    int id = 1,
    String name = '景點',
    String introduction = '',
    String openTime = '',
    String distric = '',
    String ticket = '',
    String modified = '2026-01-01',
    List<AttractionCategory> categories = const [],
    List<AttractionTag> targets = const [],
    List<AttractionTag> friendlies = const [],
    double? nlat,
    double? elong,
  }) {
    return Attraction(
      id: id,
      name: name,
      introduction: introduction,
      openTime: openTime,
      distric: distric,
      address: '',
      tel: '',
      officialSite: '',
      facebook: '',
      ticket: ticket,
      remind: '',
      modified: modified,
      url: '',
      categories: categories,
      targets: targets,
      friendlies: friendlies,
      images: const [],
      nlat: nlat,
      elong: elong,
    );
  }

  List<Attraction> displayAll(
    List<Attraction> source, {
    AttractionSortOrder sortOrder = AttractionSortOrder.apiOrder,
    Set<int> selectedCategoryIds = const {},
    String distric = '',
    Set<AttractionTargetFilter> selectedTargets = const {},
    Set<AttractionFacilityFilter> selectedFacilities = const {},
    bool openNowOnly = false,
    AttractionTimeSlotFilter timeSlotFilter = AttractionTimeSlotFilter.all,
    DistanceFilter distanceFilter = DistanceFilter.unlimited,
    double? userLat,
    double? userLng,
  }) {
    return AttractionListState.computeDisplayItems(
      source,
      sortOrder: sortOrder,
      selectedCategoryIds: selectedCategoryIds,
      distric: distric,
      selectedTargets: selectedTargets,
      selectedFacilities: selectedFacilities,
      openNowOnly: openNowOnly,
      timeSlotFilter: timeSlotFilter,
      distanceFilter: distanceFilter,
      userLat: userLat,
      userLng: userLng,
    );
  }

  group('AttractionListState.computeDisplayItems — 目前開放篩選', () {
    test('openNowOnly 只保留目前有開放的景點', () {
      final open = buildAttraction(name: '開放中', openTime: '00:00-23:59');
      final closed = buildAttraction(id: 2, name: '已打烊', openTime: '以現場公告為準');
      final result = displayAll([open, closed], openNowOnly: true);
      expect(result.map((a) => a.name), ['開放中']);
    });
  });

  group('AttractionListState.computeDisplayItems — 時段推薦篩選', () {
    test('早上時段：內容需符合早上關鍵字，且在早上取樣時間點需為開放中', () {
      final morningGood = buildAttraction(
        name: '象山步道',
        introduction: '熱門登山步道',
        openTime: '00:00-23:59', // Open at any time
      );
      final morningWrongKeyword = buildAttraction(
        id: 2,
        name: '夜市小吃',
        introduction: '知名夜市商圈',
        openTime: '00:00-23:59',
      );
      final morningNotOpenAt9am = buildAttraction(
        id: 3,
        name: '晚間步道',
        introduction: '知名步道',
        openTime: '18:00-23:00', // Sampling at 9 AM is not open.
      );
      final result = displayAll([
        morningGood,
        morningWrongKeyword,
        morningNotOpenAt9am,
      ], timeSlotFilter: AttractionTimeSlotFilter.morning);
      expect(result.map((a) => a.name), ['象山步道']);
    });
  });

  group('AttractionListState.computeDisplayItems — 分類/行政區/對象/友善設施篩選', () {
    test('selectedCategoryIds 只保留符合任一分類的景點', () {
      final a = buildAttraction(
        name: '博物館',
        categories: const [AttractionCategory(id: 10, name: '藝文館所')],
      );
      final b = buildAttraction(
        id: 2,
        name: '公園',
        categories: const [AttractionCategory(id: 20, name: '戶外踏青')],
      );
      final result = displayAll([a, b], selectedCategoryIds: {10});
      expect(result.map((x) => x.name), ['博物館']);
    });

    test('distric 篩選只保留完全相符（trim 後）的景點', () {
      final a = buildAttraction(name: '信義景點', distric: '信義區');
      final b = buildAttraction(id: 2, name: '士林景點', distric: '士林區');
      final result = displayAll([a, b], distric: '信義區');
      expect(result.map((x) => x.name), ['信義景點']);
    });

    test('selectedTargets 依 target apiId 比對', () {
      final hikerSpot = buildAttraction(
        name: '登山口',
        targets: const [AttractionTag(id: 66, name: '健行族')],
      );
      final other = buildAttraction(id: 2, name: '一般景點');
      final result = displayAll(
        [hikerSpot, other],
        selectedTargets: {AttractionTargetFilter.hiker},
      );
      expect(result.map((x) => x.name), ['登山口']);
    });

    test('selectedFacilities 依 friendly apiId 比對', () {
      final accessible = buildAttraction(
        name: '無障礙景點',
        friendlies: const [AttractionTag(id: 392, name: '無障礙')],
      );
      final other = buildAttraction(id: 2, name: '一般景點');
      final result = displayAll(
        [accessible, other],
        selectedFacilities: {AttractionFacilityFilter.accessible},
      );
      expect(result.map((x) => x.name), ['無障礙景點']);
    });
  });

  group('AttractionListState.computeDisplayItems — 距離篩選', () {
    const userLat = 25.0330;
    const userLng = 121.5654;

    test('未提供使用者座標時，只要設定距離篩選就整批排除', () {
      final a = buildAttraction(
        name: 'A',
        nlat: 25.0330,
        elong: 121.5654,
      );
      final result = displayAll([a], distanceFilter: DistanceFilter.km1);
      expect(result, isEmpty);
    });

    test('沒有座標的景點在距離篩選啟用時一律被排除', () {
      final noCoord = buildAttraction(name: '無座標');
      final result = displayAll(
        [noCoord],
        distanceFilter: DistanceFilter.km1,
        userLat: userLat,
        userLng: userLng,
      );
      expect(result, isEmpty);
    });

    test('在門檻內保留、超過門檻排除', () {
      final near = buildAttraction(
        name: '附近',
        nlat: 25.0330,
        elong: 121.5654,
      );
      final far = buildAttraction(id: 2, name: '很遠', nlat: 10, elong: 10);
      final result = displayAll(
        [near, far],
        distanceFilter: DistanceFilter.km1,
        userLat: userLat,
        userLng: userLng,
      );
      expect(result.map((x) => x.name), ['附近']);
    });
  });

  group('AttractionListState.computeDisplayItems — 排序', () {
    test('apiOrder 維持原始順序', () {
      final a = buildAttraction(name: 'B');
      final b = buildAttraction(id: 2, name: 'A');
      final result = displayAll([a, b]);
      expect(result.map((x) => x.name), ['B', 'A']);
    });

    test('nameAZ 依名稱字典序排序', () {
      final a = buildAttraction(name: 'Zebra');
      final b = buildAttraction(id: 2, name: 'Apple');
      final result = displayAll([a, b], sortOrder: AttractionSortOrder.nameAZ);
      expect(result.map((x) => x.name), ['Apple', 'Zebra']);
    });

    test('modifiedNewest 依 modified 字串降冪排序', () {
      final older = buildAttraction(name: '舊');
      final newer = buildAttraction(id: 2, name: '新', modified: '2026-06-01');
      final result = displayAll([
        older,
        newer,
      ], sortOrder: AttractionSortOrder.modifiedNewest);
      expect(result.map((x) => x.name), ['新', '舊']);
    });

    test('distanceAsc：有座標的景點依距離排序，沒有座標的排到最後', () {
      const userLat = 25.0330;
      const userLng = 121.5654;
      final near = buildAttraction(
        name: '近',
        nlat: 25.0330,
        elong: 121.5654,
      );
      final far = buildAttraction(id: 2, name: '遠', nlat: 10, elong: 10);
      final noCoord = buildAttraction(id: 3, name: '無座標');
      final result = displayAll(
        [far, noCoord, near],
        sortOrder: AttractionSortOrder.distanceAsc,
        userLat: userLat,
        userLng: userLng,
      );
      expect(result.map((x) => x.name), ['近', '遠', '無座標']);
    });

    test('distanceAsc 在沒有使用者座標時維持篩選後的原始順序', () {
      final a = buildAttraction(name: 'A');
      final b = buildAttraction(id: 2, name: 'B');
      final result = displayAll([
        a,
        b,
      ], sortOrder: AttractionSortOrder.distanceAsc);
      expect(result.map((x) => x.name), ['A', 'B']);
    });
  });

  group(
    'AttractionListState — availableDistrics / availableCategories / isDefaultFilter',
    () {
      test('availableDistrics 去重、排除空白並排序', () {
        final state = const AttractionListState().copyWith(
          allItems: [
            buildAttraction(distric: '信義區'),
            buildAttraction(id: 2, distric: '士林區'),
            buildAttraction(id: 3, distric: '信義區'),
            buildAttraction(id: 4, distric: '  '),
          ],
        );
        expect(state.availableDistrics, ['信義區', '士林區']);
      });

      test('availableCategories 依 id 去重，忽略 id=0 或名稱為空的分類', () {
        final state = const AttractionListState().copyWith(
          allItems: [
            buildAttraction(
              categories: const [
                AttractionCategory(id: 1, name: '博物館'),
                AttractionCategory(id: 0, name: '忽略我'),
                AttractionCategory(id: 2, name: ''),
              ],
            ),
            buildAttraction(
              id: 2,
              categories: const [AttractionCategory(id: 1, name: '博物館')],
            ),
          ],
        );
        expect(state.availableCategories.map((c) => c.id), [1]);
      });

      test('isDefaultFilter 只有在所有篩選都是預設值時才為 true', () {
        const defaultState = AttractionListState();
        expect(defaultState.isDefaultFilter, isTrue);
        final changed = defaultState.copyWith(openNowOnly: true);
        expect(changed.isDefaultFilter, isFalse);
      });
    },
  );
}
