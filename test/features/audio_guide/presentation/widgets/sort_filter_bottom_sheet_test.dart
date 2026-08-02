import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/nearby/nearby_models.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/enums/sort_filter_enums.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/widgets/sort_filter_bottom_sheet.dart';

typedef _Result = (SortOrder, FilterType, DistanceFilter);

class _Harness extends StatelessWidget {
  const _Harness({required this.onResult});

  final void Function(_Result?) onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await showModalBottomSheet<_Result>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const SortFilterBottomSheet(
                  initialSortOrder: SortOrder.dateNewest,
                  initialFilterType: FilterType.all,
                  initialDistanceFilter: DistanceFilter.unlimited,
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

/// Expand the test surface to avoid long BottomSheet options being clipped
/// which can cause tap() to miss the target.
/// Must be called via tester.binding inside testWidgets; do not put it in setUp/tearDown.
Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('SortFilterBottomSheet', () {
    testWidgets('顯示各區塊標題', (tester) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(_Harness(onResult: (_) {}));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('下載狀態'), findsOneWidget);
      expect(find.text('距離範圍'), findsOneWidget);
      expect(find.text('排序'), findsOneWidget);
    });

    testWidgets('選擇「已下載」後套用，結果帶回 FilterType.downloaded', (tester) async {
      await _useTallSurface(tester);
      _Result? result;
      await tester.pumpWidget(_Harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('已下載'));
      await tester.pump();
      await tester.tap(find.text('套用'));
      await tester.pumpAndSettle();
      expect(result?.$2, FilterType.downloaded);
    });

    testWidgets('選擇距離篩選後套用，結果帶回該距離', (tester) async {
      await _useTallSurface(tester);
      _Result? result;
      await tester.pumpWidget(_Harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1km'));
      await tester.pump();
      await tester.tap(find.text('套用'));
      await tester.pumpAndSettle();
      expect(result?.$3, DistanceFilter.km1);
    });

    testWidgets('選擇排序方式後套用，結果帶回該排序', (tester) async {
      await _useTallSurface(tester);
      _Result? result;
      await tester.pumpWidget(_Harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('名稱 A-Z'));
      await tester.pump();
      await tester.tap(find.text('套用'));
      await tester.pumpAndSettle();
      expect(result?.$1, SortOrder.nameAZ);
    });

    testWidgets('先改選項再按重設，套用後回傳全部預設值', (tester) async {
      await _useTallSurface(tester);
      _Result? result;
      await tester.pumpWidget(_Harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('已下載'));
      await tester.pump();
      await tester.tap(find.text('重設'));
      await tester.pump();
      await tester.tap(find.text('套用'));
      await tester.pumpAndSettle();
      expect(result?.$1, SortOrder.dateNewest);
      expect(result?.$2, FilterType.all);
      expect(result?.$3, DistanceFilter.unlimited);
    });
  });
}
