import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/domain/entities/exercise_summary_data.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/presentation/widgets/session_summary_card.dart';

void main() {
  Widget buildSubject(ExerciseSummaryData summary) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => SessionSummaryCard(summary: summary),
            ),
            child: const Text('開啟摘要'),
          ),
        ),
      ),
    );
  }

  group('SessionSummaryCard', () {
    testWidgets('顯示導覽名稱、時長、步數與公尺距離', (tester) async {
      final summary = ExerciseSummaryData(
        guideName: '故宮語音導覽',
        startTime: DateTime(2026, 7, 25, 10),
        endTime: DateTime(2026, 7, 25, 10, 12, 5),
        steps: 1234,
        distanceMeters: 850,
      );
      await tester.pumpWidget(buildSubject(summary));
      await tester.tap(find.text('開啟摘要'));
      await tester.pumpAndSettle();
      expect(find.text('故宮語音導覽'), findsOneWidget);
      expect(find.text('導覽完成'), findsOneWidget);
      expect(find.text('12:05'), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
      expect(find.text('850 公尺'), findsOneWidget);
      expect(find.text('時長'), findsOneWidget);
      expect(find.text('步數'), findsOneWidget);
      expect(find.text('距離'), findsOneWidget);
    });

    testWidgets('超過一公里時使用公里顯示（用 1500 公尺避免四捨五入邊界值）', (tester) async {
      final summary = ExerciseSummaryData(
        guideName: '台北城市導覽',
        startTime: DateTime(2026, 7, 25, 10),
        endTime: DateTime(2026, 7, 25, 11, 1, 9),
        steps: 4567,
        distanceMeters:
            1500, // 1.5 km, avoids rounding boundary for a stable result
      );
      await tester.pumpWidget(buildSubject(summary));
      await tester.tap(find.text('開啟摘要'));
      await tester.pumpAndSettle();
      expect(find.text('61:09'), findsOneWidget);
      expect(find.text('1.5 公里'), findsOneWidget);
    });

    testWidgets('點擊完成關閉摘要', (tester) async {
      final summary = ExerciseSummaryData(
        guideName: '測試導覽',
        startTime: DateTime(2026, 7, 25, 10),
        endTime: DateTime(2026, 7, 25, 10, 5),
        steps: 100,
        distanceMeters: 200,
      );
      await tester.pumpWidget(buildSubject(summary));
      await tester.tap(find.text('開啟摘要'));
      await tester.pumpAndSettle();
      expect(find.byType(SessionSummaryCard), findsOneWidget);
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.byType(SessionSummaryCard), findsNothing);
    });
  });
}
