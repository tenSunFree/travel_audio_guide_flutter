import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/enums/attraction_sort_filter_enums.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/widgets/attraction_condition_summary_bar.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AttractionConditionSummaryBar', () {
    testWidgets('顯示預設文字且不出現「重設」', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AttractionConditionSummaryBar(
            sortOrder: AttractionSortOrder.apiOrder,
            categoryIds: const {},
            distric: '',
            targets: const {},
            facilities: const {},
            openNowOnly: false,
            timeSlotFilter: AttractionTimeSlotFilter.all,
            availableCategories: const [],
            isNonDefault: false,
            onReset: () {},
          ),
        ),
      );
      expect(find.textContaining('預設'), findsOneWidget);
      expect(find.text('重設'), findsNothing);
    });

    testWidgets('非預設時顯示排序 label 與行政區，並出現「重設」', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AttractionConditionSummaryBar(
            sortOrder: AttractionSortOrder.distanceAsc,
            categoryIds: const {},
            distric: '信義區',
            targets: const {},
            facilities: const {},
            openNowOnly: true,
            timeSlotFilter: AttractionTimeSlotFilter.morning,
            availableCategories: const [],
            isNonDefault: true,
            onReset: () {},
          ),
        ),
      );
      expect(find.textContaining('現在可去'), findsOneWidget);
      expect(find.textContaining('早上推薦'), findsOneWidget);
      expect(find.textContaining('信義區'), findsOneWidget);
      expect(find.text('重設'), findsOneWidget);
    });

    testWidgets('點擊「重設」呼叫 onReset', (tester) async {
      var resetCalled = false;
      await tester.pumpWidget(
        _wrap(
          AttractionConditionSummaryBar(
            sortOrder: AttractionSortOrder.apiOrder,
            categoryIds: const {},
            distric: '大安區',
            targets: const {},
            facilities: const {},
            openNowOnly: false,
            timeSlotFilter: AttractionTimeSlotFilter.all,
            availableCategories: const [],
            isNonDefault: true,
            onReset: () => resetCalled = true,
          ),
        ),
      );
      await tester.tap(find.text('重設'));
      await tester.pump();
      expect(resetCalled, isTrue);
    });
  });
}
