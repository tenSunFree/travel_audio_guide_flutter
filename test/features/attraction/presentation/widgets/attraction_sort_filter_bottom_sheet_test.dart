import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/nearby/nearby_models.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/enums/attraction_sort_filter_enums.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/widgets/attraction_sort_filter_bottom_sheet.dart';

class _Harness extends StatelessWidget {
  const _Harness({required this.onResult});

  final void Function(AttractionFilterResult?) onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await showModalBottomSheet<AttractionFilterResult>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AttractionSortFilterBottomSheet(
                  initialSortOrder: AttractionSortOrder.apiOrder,
                  initialCategoryIds: {},
                  initialDistric: '',
                  initialTargets: {},
                  initialFacilities: {},
                  initialOpenNowOnly: false,
                  initialTimeSlotFilter: AttractionTimeSlotFilter.all,
                  initialDistanceFilter: DistanceFilter.unlimited,
                  availableCategories: [],
                  availableDistrics: ['信義區', '大安區'],
                ),
              );
              onResult(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}

/// Increase the test surface size to prevent long BottomSheet option lists
/// from being clipped off-screen, which can cause tap() to miss targets.
///
/// Must be called inside a testWidgets body (use tester.binding); it should
/// not be placed in setUp/tearDown.
Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('AttractionSortFilterBottomSheet', () {
    testWidgets('顯示各個區塊標題', (tester) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(_Harness(onResult: (_) {}));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('開放狀態'), findsOneWidget);
      expect(find.text('距離範圍'), findsOneWidget);
      expect(find.text('推薦時段'), findsOneWidget);
      expect(find.text('排序'), findsOneWidget);
      expect(find.text('行政區'), findsOneWidget);
      expect(find.text('適合族群'), findsOneWidget);
      expect(find.text('友善設施'), findsOneWidget);
    });

    testWidgets('切換「只看現在可去」並按套用，結果帶回 openNowOnly=true', (tester) async {
      await _useTallSurface(tester);
      AttractionFilterResult? result;
      await tester.pumpWidget(_Harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('只看現在可去'));
      await tester.pump();
      await tester.tap(find.text('套用'));
      await tester.pumpAndSettle();
      expect(result?.openNowOnly, isTrue);
    });

    testWidgets('選擇距離篩選後套用，結果帶回選擇的距離', (tester) async {
      await _useTallSurface(tester);
      AttractionFilterResult? result;
      await tester.pumpWidget(_Harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1km'));
      await tester.pump();
      await tester.tap(find.text('套用'));
      await tester.pumpAndSettle();
      expect(result?.distanceFilter, DistanceFilter.km1);
    });

    testWidgets('選擇推薦時段後套用，結果帶回該時段', (tester) async {
      await _useTallSurface(tester);
      AttractionFilterResult? result;
      await tester.pumpWidget(_Harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('早上推薦'));
      await tester.pump();
      await tester.tap(find.text('套用'));
      await tester.pumpAndSettle();
      expect(result?.timeSlotFilter, AttractionTimeSlotFilter.morning);
    });

    testWidgets('選擇排序方式後套用，結果帶回該排序', (tester) async {
      await _useTallSurface(tester);
      AttractionFilterResult? result;
      await tester.pumpWidget(_Harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('名稱 A-Z'));
      await tester.pump();
      await tester.tap(find.text('套用'));
      await tester.pumpAndSettle();
      expect(result?.sortOrder, AttractionSortOrder.nameAZ);
    });

    testWidgets('選擇行政區後套用，結果帶回該行政區', (tester) async {
      await _useTallSurface(tester);
      AttractionFilterResult? result;
      await tester.pumpWidget(_Harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('大安區'));
      await tester.pump();
      await tester.tap(find.text('套用'));
      await tester.pumpAndSettle();
      expect(result?.distric, '大安區');
    });

    testWidgets('選擇適合族群後套用，結果帶回該族群', (tester) async {
      await _useTallSurface(tester);
      AttractionFilterResult? result;
      await tester.pumpWidget(_Harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('健行族'));
      await tester.pump();
      await tester.tap(find.text('套用'));
      await tester.pumpAndSettle();
      expect(result?.targets, contains(AttractionTargetFilter.hiker));
    });

    testWidgets('選擇友善設施後套用，結果帶回該設施', (tester) async {
      await _useTallSurface(tester);
      AttractionFilterResult? result;
      await tester.pumpWidget(_Harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('♿ 無障礙'));
      await tester.pump();
      await tester.tap(find.text('套用'));
      await tester.pumpAndSettle();
      expect(result?.facilities, contains(AttractionFacilityFilter.accessible));
    });

    testWidgets('先改選項再按重設，套用後回傳全部預設值', (tester) async {
      await _useTallSurface(tester);
      AttractionFilterResult? result;
      await tester.pumpWidget(_Harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('大安區'));
      await tester.pump();
      await tester.tap(find.text('只看現在可去'));
      await tester.pump();
      await tester.tap(find.text('重設'));
      await tester.pump();
      await tester.tap(find.text('套用'));
      await tester.pumpAndSettle();
      expect(result?.distric, '');
      expect(result?.sortOrder, AttractionSortOrder.apiOrder);
      expect(result?.openNowOnly, isFalse);
      expect(result?.timeSlotFilter, AttractionTimeSlotFilter.all);
      expect(result?.distanceFilter, DistanceFilter.unlimited);
    });
  });
}
