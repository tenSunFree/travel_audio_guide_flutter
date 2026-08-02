import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/nearby/nearby_models.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity.dart';
import 'package:flutter_travel_audio_guide/features/activity/presentation/controllers/activity_list_controller.dart';
import 'package:flutter_travel_audio_guide/features/activity/presentation/enums/activity_sort_filter_enums.dart';

void main() {
  String two(int n) => n.toString().padLeft(2, '0');
  String isoWithTime(DateTime d) =>
      '${d.year}-${two(d.month)}-${two(d.day)}T${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  String dateOnly(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  Activity buildActivity({
    int id = 1,
    String title = '活動',
    String begin = '',
    String end = '',
    String ticket = '',
    String distric = '',
    String nlat = '',
    String elong = '',
  }) {
    return Activity(
      id: id,
      title: title,
      description: '',
      begin: begin,
      end: end,
      posted: '',
      modified: '',
      url: '',
      address: '',
      distric: distric,
      nlat: nlat,
      elong: elong,
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

  List<Activity> displayAll(
    List<Activity> items, {
    ActivitySortOrder sort = ActivitySortOrder.beginAsc,
    ActivityStatusFilter status = ActivityStatusFilter.all,
    ActivityFeeFilter fee = ActivityFeeFilter.all,
    String distric = '',
    DistanceFilter distanceFilter = DistanceFilter.unlimited,
    double? userLat,
    double? userLng,
  }) {
    return ActivityListState.computeDisplayItems(
      items,
      sort,
      status,
      fee,
      distric,
      distanceFilter: distanceFilter,
      userLat: userLat,
      userLng: userLng,
    );
  }

  group('ActivityListState.computeDisplayItems — 狀態篩選', () {
    test('ongoing：目前時間介於精確的 begin/end 之間才算進行中', () {
      final now = DateTime.now();
      final ongoing = buildActivity(
        title: '進行中',
        begin: isoWithTime(now.subtract(const Duration(hours: 1))),
        end: isoWithTime(now.add(const Duration(hours: 1))),
      );
      final notYet = buildActivity(
        id: 2,
        title: '尚未開始',
        begin: isoWithTime(now.add(const Duration(days: 5))),
        end: isoWithTime(now.add(const Duration(days: 6))),
      );

      final result = displayAll([
        ongoing,
        notYet,
      ], status: ActivityStatusFilter.ongoing);

      expect(result.map((a) => a.title), ['進行中']);
    });

    test('upcoming：2 小時內即將開始才算即將開始', () {
      final now = DateTime.now();
      final soon = buildActivity(
        title: '即將開始',
        begin: isoWithTime(now.add(const Duration(hours: 1))),
        end: isoWithTime(now.add(const Duration(hours: 3))),
      );
      final tooLate = buildActivity(
        id: 2,
        title: '太久之後',
        begin: isoWithTime(now.add(const Duration(hours: 5))),
        end: isoWithTime(now.add(const Duration(hours: 6))),
      );

      final result = displayAll([
        soon,
        tooLate,
      ], status: ActivityStatusFilter.upcoming);

      expect(result.map((a) => a.title), ['即將開始']);
    });

    test('today：只有日期區間（無精確時間）且今天落在區間內才算今日活動', () {
      final now = DateTime.now();
      final todayEvent = buildActivity(
        title: '今日活動',
        begin: dateOnly(now),
        end: dateOnly(now.add(const Duration(days: 2))),
      );
      final futureEvent = buildActivity(
        id: 2,
        title: '未來活動',
        begin: dateOnly(now.add(const Duration(days: 10))),
        end: dateOnly(now.add(const Duration(days: 12))),
      );

      final result = displayAll([
        todayEvent,
        futureEvent,
      ], status: ActivityStatusFilter.today);

      expect(result.map((a) => a.title), ['今日活動']);
    });

    test('all：狀態篩選為 all 時，無法解析日期或已結束的活動也會被包含', () {
      final now = DateTime.now();
      final ended = buildActivity(
        title: '已結束',
        begin: isoWithTime(now.subtract(const Duration(days: 3))),
        end: isoWithTime(now.subtract(const Duration(days: 2))),
      );
      final unparsable = buildActivity(
        id: 2,
        title: '日期異常',
        begin: '不是日期',
        end: '也不是',
      );

      final result = displayAll([ended, unparsable]);

      expect(result.map((a) => a.title).toSet(), {'已結束', '日期異常'});
    });

    test('已結束或日期異常的活動在特定狀態篩選下會被排除', () {
      final now = DateTime.now();
      final ended = buildActivity(
        title: '已結束',
        begin: isoWithTime(now.subtract(const Duration(days: 3))),
        end: isoWithTime(now.subtract(const Duration(days: 2))),
      );
      final unparsable = buildActivity(
        id: 2,
        title: '日期異常',
        begin: '不是日期',
        end: '也不是',
      );

      expect(
        displayAll([ended, unparsable], status: ActivityStatusFilter.ongoing),
        isEmpty,
      );
      expect(
        displayAll([ended, unparsable], status: ActivityStatusFilter.today),
        isEmpty,
      );
    });
  });

  group('ActivityListState.computeDisplayItems — 費用篩選', () {
    test('free 只保留 ticket 為空白的活動；paid 只保留 ticket 有內容的活動', () {
      final free = buildActivity(title: '免費活動', ticket: '  ');
      final paid = buildActivity(id: 2, title: '付費活動', ticket: '100元');

      expect(
        displayAll([
          free,
          paid,
        ], fee: ActivityFeeFilter.free).map((a) => a.title),
        ['免費活動'],
      );
      expect(
        displayAll([
          free,
          paid,
        ], fee: ActivityFeeFilter.paid).map((a) => a.title),
        ['付費活動'],
      );
    });
  });

  group('ActivityListState.computeDisplayItems — 行政區篩選', () {
    test('只保留行政區完全相符（trim 後）的活動', () {
      final a1 = buildActivity(title: '信義區活動', distric: '信義區');
      final a2 = buildActivity(id: 2, title: '士林區活動', distric: '士林區');

      final result = displayAll([a1, a2], distric: '信義區');

      expect(result.map((a) => a.title), ['信義區活動']);
    });
  });

  group('ActivityListState.computeDisplayItems — 距離篩選', () {
    const userLat = 25.0330;
    const userLng = 121.5654;
    Activity nearby() =>
        buildActivity(title: '附近活動', nlat: '25.0330', elong: '121.5654');
    Activity far() =>
        buildActivity(id: 2, title: '很遠的活動', nlat: '10.0000', elong: '10.0000');
    Activity invalidCoord() =>
        buildActivity(id: 3, title: '座標異常', nlat: 'abc', elong: 'def');

    test('未提供使用者座標時，只要設定距離篩選就整批排除', () {
      final result = displayAll([
        nearby(),
        far(),
      ], distanceFilter: DistanceFilter.km1);
      expect(result, isEmpty);
    });

    test('座標無法解析的活動一律被排除', () {
      final result = displayAll(
        [invalidCoord()],
        distanceFilter: DistanceFilter.km1,
        userLat: userLat,
        userLng: userLng,
      );
      expect(result, isEmpty);
    });

    test('在距離門檻內的活動保留，超過門檻的被排除', () {
      final result = displayAll(
        [nearby(), far()],
        distanceFilter: DistanceFilter.km1,
        userLat: userLat,
        userLng: userLng,
      );
      expect(result.map((a) => a.title), ['附近活動']);
    });

    test('distanceFilter 為 unlimited 時不受座標影響，全部保留', () {
      final result = displayAll([
        nearby(),
        far(),
        invalidCoord(),
      ]);
      expect(result.length, 3);
    });
  });

  group('ActivityListState.computeDisplayItems — 排序', () {
    test('beginAsc / beginDesc 依 begin 字串排序', () {
      final a = buildActivity(title: 'A', begin: '2026-01-01');
      final b = buildActivity(id: 2, title: 'B', begin: '2026-06-01');
      expect(
        displayAll([
          b,
          a,
        ]).map((x) => x.title),
        ['A', 'B'],
      );
      expect(
        displayAll([
          a,
          b,
        ], sort: ActivitySortOrder.beginDesc).map((x) => x.title),
        ['B', 'A'],
      );
    });

    test('nameAZ 依 title 字典序排序', () {
      final a = buildActivity(title: 'Zebra');
      final b = buildActivity(id: 2, title: 'Apple');
      final result = displayAll([a, b], sort: ActivitySortOrder.nameAZ);
      expect(result.map((x) => x.title), ['Apple', 'Zebra']);
    });

    test('distanceAsc 在有使用者座標時依距離近到遠排序', () {
      const userLat = 25.0330;
      const userLng = 121.5654;
      final near = buildActivity(
        title: '近',
        nlat: '25.0330',
        elong: '121.5654',
      );
      final far = buildActivity(id: 2, title: '遠', nlat: '10.0', elong: '10.0');
      final result = displayAll(
        [far, near],
        sort: ActivitySortOrder.distanceAsc,
        userLat: userLat,
        userLng: userLng,
      );
      expect(result.map((x) => x.title), ['近', '遠']);
    });

    test('distanceAsc 在沒有使用者座標時維持原本篩選後的順序', () {
      final a = buildActivity(title: 'A');
      final b = buildActivity(id: 2, title: 'B');
      final result = displayAll([a, b], sort: ActivitySortOrder.distanceAsc);
      expect(result.map((x) => x.title), ['A', 'B']);
    });
  });

  group('ActivityListState.activityStatusText', () {
    test('進行中的活動不顯示徽章文字', () {
      final now = DateTime.now();
      final a = buildActivity(
        begin: isoWithTime(now.subtract(const Duration(hours: 1))),
        end: isoWithTime(now.add(const Duration(hours: 1))),
      );
      expect(ActivityListState.activityStatusText(a, now), isNull);
    });

    test('即將開始顯示「今天稍晚開始」', () {
      final now = DateTime.now();
      final a = buildActivity(
        begin: isoWithTime(now.add(const Duration(hours: 1))),
        end: isoWithTime(now.add(const Duration(hours: 3))),
      );
      expect(ActivityListState.activityStatusText(a, now), '今天稍晚開始');
    });

    test('僅日期區間且今天在範圍內顯示「今日活動」', () {
      final now = DateTime.now();
      final a = buildActivity(begin: dateOnly(now), end: dateOnly(now));
      expect(ActivityListState.activityStatusText(a, now), '今日活動');
    });

    test('已結束或無法解析日期時不顯示徽章文字', () {
      final now = DateTime.now();
      final ended = buildActivity(
        begin: isoWithTime(now.subtract(const Duration(days: 2))),
        end: isoWithTime(now.subtract(const Duration(days: 1))),
      );
      final unknown = buildActivity(begin: '不是日期', end: '也不是');
      expect(ActivityListState.activityStatusText(ended, now), isNull);
      expect(ActivityListState.activityStatusText(unknown, now), isNull);
    });
  });

  group(
    'ActivityListState — availableDistrics / isDefaultFilter / copyWith',
    () {
      test('availableDistrics 會去重、忽略空白行政區並排序', () {
        final state = ActivityListState.initial().copyWith(
          allItems: [
            buildActivity(distric: '信義區'),
            buildActivity(id: 2, distric: '士林區'),
            buildActivity(id: 3, distric: '信義區'),
            buildActivity(id: 4, distric: '  '),
          ],
        );
        expect(state.availableDistrics, ['信義區', '士林區']);
      });

      test('isDefaultFilter 只有在所有篩選條件都是預設值時才為 true', () {
        final defaultState = ActivityListState.initial();
        expect(defaultState.isDefaultFilter, isTrue);
        final changedState = defaultState.copyWith(
          feeFilter: ActivityFeeFilter.free,
        );
        expect(changedState.isDefaultFilter, isFalse);
      });

      test('copyWith 的 clearErrorMessage 會強制把 errorMessage 清成 null', () {
        final withError = ActivityListState.initial().copyWith(
          errorMessage: '發生錯誤',
        );
        expect(withError.errorMessage, '發生錯誤');
        final cleared = withError.copyWith(clearErrorMessage: true);
        expect(cleared.errorMessage, isNull);
      });
    },
  );
}
