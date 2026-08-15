import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/nearby/nearby_models.dart';
import 'package:flutter_travel_audio_guide/features/activity/presentation/enums/activity_sort_filter_enums.dart';
import 'package:flutter_travel_audio_guide/features/activity/presentation/widgets/activity_sort_filter_bottom_sheet.dart';

Widget wrap({
  ActivitySortOrder sortOrder = ActivitySortOrder.beginAsc,
  ActivityStatusFilter statusFilter = ActivityStatusFilter.all,
  ActivityFeeFilter feeFilter = ActivityFeeFilter.all,
  String distric = '',
  DistanceFilter distanceFilter = DistanceFilter.unlimited,
  List<String> availableDistrics = const ['信義區', '中正區'],
}) {
  return MaterialApp(
    home: Scaffold(
      body: ActivitySortFilterBottomSheet(
        initialSortOrder: sortOrder,
        initialStatusFilter: statusFilter,
        initialFeeFilter: feeFilter,
        initialDistric: distric,
        initialDistanceFilter: distanceFilter,
        availableDistrics: availableDistrics,
      ),
    ),
  );
}

void main() {
  group('ActivitySortFilterBottomSheet — 顯示', () {
    testWidgets('顯示主要區塊標題與按鈕', (tester) async {
      await tester.pumpWidget(wrap());
      expect(find.text('排序與篩選'), findsOneWidget);
      expect(find.text('活動狀態'), findsOneWidget);
      expect(find.text('距離範圍'), findsOneWidget);
      expect(find.text('排序'), findsOneWidget);
      expect(find.text('費用'), findsOneWidget);
      expect(find.text('行政區'), findsOneWidget);
      expect(find.text('重設'), findsOneWidget);
      expect(find.text('套用'), findsOneWidget);
    });

    testWidgets('顯示所有 ActivityStatusFilter 選項', (tester) async {
      await tester.pumpWidget(wrap());
      for (final filter in ActivityStatusFilter.values) {
        expect(find.text(filter.label), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('顯示所有排序選項', (tester) async {
      await tester.pumpWidget(wrap());
      for (final sort in ActivitySortOrder.values) {
        expect(find.text(sort.label), findsOneWidget);
      }
    });

    testWidgets('顯示所有距離篩選選項', (tester) async {
      await tester.pumpWidget(wrap());
      for (final filter in DistanceFilter.values) {
        await tester.scrollUntilVisible(find.text(filter.label), 100);
        expect(find.text(filter.label), findsOneWidget);
      }
    });

    testWidgets('顯示行政區選項', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.scrollUntilVisible(find.text('信義區'), 100);
      expect(find.text('信義區'), findsOneWidget);
      expect(find.text('中正區'), findsOneWidget);
    });

    testWidgets('沒有行政區資料時不顯示行政區區塊', (tester) async {
      await tester.pumpWidget(wrap(availableDistrics: const []));
      expect(find.text('行政區'), findsNothing);
    });
  });

  group('ActivitySortFilterBottomSheet — 操作', () {
    testWidgets('可以切換活動狀態', (tester) async {
      await tester.pumpWidget(wrap());
      const target = ActivityStatusFilter.ongoing;
      await tester.tap(find.text(target.label));
      await tester.pump();
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, target.label),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('可以切換排序方式（RadioGroup 的 groupValue 會更新）', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text(ActivitySortOrder.nameAZ.label));
      await tester.pump();
      final radioGroup = tester.widget<RadioGroup<ActivitySortOrder>>(
        find.byType(RadioGroup<ActivitySortOrder>),
      );
      expect(radioGroup.groupValue, ActivitySortOrder.nameAZ);
    });

    testWidgets('可以切換距離篩選', (tester) async {
      await tester.pumpWidget(wrap());
      const target = DistanceFilter.km1;
      await tester.scrollUntilVisible(find.text(target.label), 100);
      await tester.tap(find.text(target.label));
      await tester.pump();
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, target.label),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('可以切換費用篩選', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.scrollUntilVisible(
        find.text(ActivityFeeFilter.free.label),
        100,
      );
      await tester.tap(find.text(ActivityFeeFilter.free.label));
      await tester.pump();
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, ActivityFeeFilter.free.label),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('可以選擇行政區', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.scrollUntilVisible(find.text('信義區'), 100);
      await tester.tap(find.text('信義區'));
      await tester.pump();
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '信義區'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('重設會把所有篩選條件還原成預設值', (tester) async {
      await tester.pumpWidget(
        wrap(
          sortOrder: ActivitySortOrder.nameAZ,
          statusFilter: ActivityStatusFilter.ongoing,
          feeFilter: ActivityFeeFilter.free,
          distric: '信義區',
          distanceFilter: DistanceFilter.km1,
        ),
      );
      await tester.tap(find.text('重設'));
      await tester.pump();
      final statusChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, ActivityStatusFilter.all.label),
      );
      expect(statusChip.selected, isTrue);
      final radioGroup = tester.widget<RadioGroup<ActivitySortOrder>>(
        find.byType(RadioGroup<ActivitySortOrder>),
      );
      expect(radioGroup.groupValue, ActivitySortOrder.beginAsc);
      // Note: ActivityFeeFilter.all.label and the "All" ChoiceChip inside
      // the district section both display the text "全部" (All), so
      // find.text('全部') would match both chips. APIs that expect a single
      // match (e.g. tester.widget() / scrollUntilVisible()) cannot be used
      // here. We use widgetList to collect all matching chips at once and
      // assert that they are all selected after reset — the fee filter's
      // "All" and the district's "All" should both be selected after reset,
      // so this assertion covers both.
      final allChipsLabeledAll = tester.widgetList<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '全部'),
      );
      expect(
        allChipsLabeledAll.length,
        2,
      ); // Fees "All" + Administrative Districts "All"
      for (final chip in allChipsLabeledAll) {
        expect(chip.selected, isTrue);
      }
    });
  });
}
