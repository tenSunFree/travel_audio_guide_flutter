import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/activity/presentation/enums/activity_sort_filter_enums.dart';
import 'package:flutter_travel_audio_guide/features/activity/presentation/widgets/activity_condition_summary_bar.dart';

Widget wrap({
  ActivitySortOrder sortOrder = ActivitySortOrder.beginAsc,
  ActivityStatusFilter statusFilter = ActivityStatusFilter.all,
  ActivityFeeFilter feeFilter = ActivityFeeFilter.all,
  String distric = '',
  bool isNonDefault = false,
  VoidCallback? onReset,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ActivityConditionSummaryBar(
        sortOrder: sortOrder,
        statusFilter: statusFilter,
        feeFilter: feeFilter,
        distric: distric,
        isNonDefault: isNonDefault,
        onReset: onReset ?? () {},
      ),
    ),
  );
}

void main() {
  group('ActivityConditionSummaryBar — 顯示', () {
    testWidgets('預設條件顯示「預設」，且不顯示重設按鈕', (tester) async {
      await tester.pumpWidget(wrap());
      expect(find.text('預設'), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.text('重設'), findsNothing);
    });

    testWidgets('非預設排序顯示排序名稱', (tester) async {
      await tester.pumpWidget(
        wrap(sortOrder: ActivitySortOrder.nameAZ, isNonDefault: true),
      );
      expect(
        find.textContaining(ActivitySortOrder.nameAZ.label),
        findsOneWidget,
      );
    });

    testWidgets('顯示活動狀態', (tester) async {
      await tester.pumpWidget(
        wrap(statusFilter: ActivityStatusFilter.ongoing, isNonDefault: true),
      );
      expect(
        find.textContaining(ActivityStatusFilter.ongoing.label),
        findsOneWidget,
      );
    });

    testWidgets('顯示費用條件', (tester) async {
      await tester.pumpWidget(
        wrap(feeFilter: ActivityFeeFilter.free, isNonDefault: true),
      );
      expect(find.textContaining(ActivityFeeFilter.free.label), findsOneWidget);
    });

    testWidgets('顯示行政區', (tester) async {
      await tester.pumpWidget(wrap(distric: '信義區', isNonDefault: true));
      expect(find.textContaining('信義區'), findsOneWidget);
    });

    testWidgets('同時顯示多個篩選條件', (tester) async {
      await tester.pumpWidget(
        wrap(
          sortOrder: ActivitySortOrder.nameAZ,
          statusFilter: ActivityStatusFilter.today,
          feeFilter: ActivityFeeFilter.free,
          distric: '中正區',
          isNonDefault: true,
        ),
      );

      expect(
        find.textContaining(ActivityStatusFilter.today.label),
        findsOneWidget,
      );
      expect(
        find.textContaining(ActivitySortOrder.nameAZ.label),
        findsOneWidget,
      );
      expect(find.textContaining(ActivityFeeFilter.free.label), findsOneWidget);
      expect(find.textContaining('中正區'), findsOneWidget);
    });
  });

  group('ActivityConditionSummaryBar — 互動', () {
    testWidgets('非預設狀態才顯示「重設」', (tester) async {
      await tester.pumpWidget(wrap(isNonDefault: true));
      expect(find.text('重設'), findsOneWidget);
    });

    testWidgets('點擊重設觸發 callback', (tester) async {
      var called = false;
      await tester.pumpWidget(
        wrap(isNonDefault: true, onReset: () => called = true),
      );
      await tester.tap(find.text('重設'));
      await tester.pump();
      expect(called, isTrue);
    });
  });
}
