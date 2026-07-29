import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/reminder/di/reminder_providers.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:flutter_travel_audio_guide/features/reminder/presentation/pages/my_journey_page.dart';

Reminder _buildReminder(int id) {
  final future = DateTime.now().add(const Duration(days: 30));
  return Reminder(
    id: id,
    sourceType: 'attraction',
    sourceId: '$id',
    title: '提醒 $id',
    targetTime: future,
    remindBeforeSeconds: 0,
    notifyTime: future,
    notificationId: id,
    routePath: '/attraction/$id',
    payloadJson: '{}',
    isEnabled: true,
    isDone: false,
    createdAt: DateTime.now(),
  );
}

void main() {
  testWidgets('清單為空時顯示提示文字', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderListProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: MyJourneyPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('我的旅程'), findsOneWidget);
    expect(find.text('尚未加入任何提醒'), findsOneWidget);
  });

  testWidgets('有資料時顯示提醒清單', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderListProvider.overrideWith(
            (ref) => Stream.value([_buildReminder(1), _buildReminder(2)]),
          ),
        ],
        child: const MaterialApp(home: MyJourneyPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('提醒 1'), findsOneWidget);
    expect(find.text('提醒 2'), findsOneWidget);
  });

  testWidgets('讀取錯誤時顯示錯誤訊息', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderListProvider.overrideWith(
            (ref) => Stream<List<Reminder>>.error('DB 壞了'),
          ),
        ],
        child: const MaterialApp(home: MyJourneyPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('讀取失敗'), findsOneWidget);
  });
}
