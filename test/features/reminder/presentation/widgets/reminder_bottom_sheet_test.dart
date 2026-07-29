import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/reminder/presentation/widgets/reminder_bottom_sheet.dart';

void main() {
  final initialTime = DateTime(2026, 8, 10, 14, 30);

  Widget buildSubject({
    DateTime? minTargetTime,
    DateTime? maxTargetTime,
    ValueChanged<ReminderBottomSheetResult?>? onClosed,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () async {
                final result =
                    await showModalBottomSheet<ReminderBottomSheetResult>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ReminderBottomSheet(
                        initialTargetTime: initialTime,
                        minTargetTime: minTargetTime,
                        maxTargetTime: maxTargetTime,
                      ),
                    );
                onClosed?.call(result);
              },
              child: const Text('開啟提醒'),
            );
          },
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('開啟提醒'));
    await tester.pumpAndSettle();
  }

  group('ReminderBottomSheet', () {
    testWidgets('顯示初始時間與所有預設選項', (tester) async {
      await tester.pumpWidget(buildSubject());
      await openSheet(tester);
      expect(find.text('加入提醒'), findsOneWidget);
      expect(find.text('提醒目標時間'), findsOneWidget);
      expect(find.text('2026/08/10 14:30'), findsOneWidget);
      expect(find.text('提前提醒'), findsOneWidget);
      expect(find.text('準時'), findsOneWidget);
      expect(find.text('5 分鐘前'), findsOneWidget);
      expect(find.text('15 分鐘前'), findsOneWidget);
      expect(find.text('30 分鐘前'), findsOneWidget);
      expect(find.text('1 小時前'), findsOneWidget);
      expect(find.text('1 天前'), findsOneWidget);
      expect(find.text('自訂'), findsOneWidget);
    });

    testWidgets('選擇十五分鐘前並儲存', (tester) async {
      ReminderBottomSheetResult? actual;
      await tester.pumpWidget(
        buildSubject(onClosed: (result) => actual = result),
      );
      await openSheet(tester);
      await tester.tap(find.text('15 分鐘前'));
      await tester.pump();
      await tester.tap(find.text('儲存提醒'));
      await tester.pumpAndSettle();
      expect(actual, isNotNull);
      expect(actual!.targetTime, initialTime);
      expect(actual!.remindBeforeSeconds, 15 * 60);
    });

    testWidgets('支援自訂小時、分鐘與秒數', (tester) async {
      ReminderBottomSheetResult? actual;
      await tester.pumpWidget(
        buildSubject(onClosed: (result) => actual = result),
      );
      await openSheet(tester);
      await tester.tap(find.text('自訂'));
      await tester.pump();
      expect(find.text('小時'), findsOneWidget);
      expect(find.text('分鐘'), findsOneWidget);
      expect(find.text('秒'), findsOneWidget);
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(3));
      await tester.enterText(fields.at(0), '1');
      await tester.enterText(fields.at(1), '2');
      await tester.enterText(fields.at(2), '3');
      await tester.pump();
      await tester.tap(find.text('儲存提醒'));
      await tester.pumpAndSettle();
      expect(actual, isNotNull);
      expect(actual!.remindBeforeSeconds, 3723);
    });

    testWidgets('自訂欄位輸入非數字時視為零', (tester) async {
      ReminderBottomSheetResult? actual;
      await tester.pumpWidget(
        buildSubject(onClosed: (result) => actual = result),
      );
      await openSheet(tester);
      await tester.tap(find.text('自訂'));
      await tester.pump();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'abc');
      await tester.enterText(fields.at(1), '5');
      await tester.enterText(fields.at(2), 'x');
      await tester.pump();
      await tester.tap(find.text('儲存提醒'));
      await tester.pumpAndSettle();
      expect(actual, isNotNull);
      expect(actual!.remindBeforeSeconds, 300);
    });

    testWidgets('點擊取消關閉 BottomSheet 並回傳 null', (tester) async {
      ReminderBottomSheetResult? actual;
      var callbackCalled = false;
      await tester.pumpWidget(
        buildSubject(
          onClosed: (result) {
            callbackCalled = true;
            actual = result;
          },
        ),
      );
      await openSheet(tester);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(callbackCalled, isTrue);
      expect(actual, isNull);
      expect(find.byType(ReminderBottomSheet), findsNothing);
    });

    testWidgets('點擊右上角關閉按鈕回傳 null', (tester) async {
      ReminderBottomSheetResult? actual;
      var callbackCalled = false;
      await tester.pumpWidget(
        buildSubject(
          onClosed: (result) {
            callbackCalled = true;
            actual = result;
          },
        ),
      );
      await openSheet(tester);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(callbackCalled, isTrue);
      expect(actual, isNull);
    });

    testWidgets('切換不同預設提醒時間', (tester) async {
      ReminderBottomSheetResult? actual;
      await tester.pumpWidget(
        buildSubject(onClosed: (result) => actual = result),
      );
      await openSheet(tester);
      await tester.tap(find.text('1 天前'));
      await tester.pump();
      await tester.tap(find.text('儲存提醒'));
      await tester.pumpAndSettle();
      expect(actual!.remindBeforeSeconds, 24 * 60 * 60);
    });
  });
}
