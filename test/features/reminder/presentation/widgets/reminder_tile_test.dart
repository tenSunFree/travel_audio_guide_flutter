import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/features/reminder/di/reminder_providers.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/usecases/delete_reminder_usecase.dart';
import 'package:flutter_travel_audio_guide/features/reminder/presentation/widgets/reminder_tile.dart';

class MockDeleteReminderUseCase extends Mock implements DeleteReminderUseCase {}

void main() {
  late MockDeleteReminderUseCase mockDelete;

  setUp(() {
    mockDelete = MockDeleteReminderUseCase();
    when(
      () => mockDelete.call(
        id: any(named: 'id'),
        notificationId: any(named: 'notificationId'),
      ),
    ).thenAnswer((_) async {});
  });

  final future = DateTime.now().add(const Duration(days: 30));
  final past = DateTime.now().subtract(const Duration(days: 30));

  String formatDateTime(DateTime time) {
    return '${time.year}/'
        '${time.month.toString().padLeft(2, '0')}/'
        '${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Reminder buildReminder({int? id = 1, DateTime? notifyTime}) {
    return Reminder(
      id: id,
      sourceType: 'attraction',
      sourceId: '1',
      title: '台北101',
      targetTime: future,
      remindBeforeSeconds: 0,
      notifyTime: notifyTime ?? future,
      notificationId: 100,
      routePath: '/attraction/1',
      payloadJson: '{}',
      isEnabled: true,
      isDone: false,
      createdAt: DateTime.now(),
    );
  }

  Widget buildSubject(Reminder reminder) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(body: ReminderTile(reminder: reminder)),
        ),
        GoRoute(
          path: '/attraction/1',
          builder: (_, _) => const Scaffold(body: Text('景點詳細頁')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [deleteReminderUseCaseProvider.overrideWithValue(mockDelete)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('顯示標題與格式化後的提醒時間', (tester) async {
    final reminder = buildReminder();
    await tester.pumpWidget(buildSubject(reminder));
    expect(find.text('台北101'), findsOneWidget);
    expect(
      find.text('提醒：${formatDateTime(reminder.notifyTime)}'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
  });

  testWidgets('已過期的提醒顯示 event_busy 圖示且點擊無反應', (tester) async {
    final expired = buildReminder(notifyTime: past);
    await tester.pumpWidget(buildSubject(expired));
    expect(find.byIcon(Icons.event_busy), findsOneWidget);
    await tester.tap(find.text('台北101'));
    await tester.pumpAndSettle();
    expect(find.text('景點詳細頁'), findsNothing);
  });

  testWidgets('點擊卡片會導航到 routePath', (tester) async {
    await tester.pumpWidget(buildSubject(buildReminder()));
    await tester.tap(find.text('台北101'));
    await tester.pumpAndSettle();
    expect(find.text('景點詳細頁'), findsOneWidget);
  });

  testWidgets('點擊刪除按鈕呼叫 DeleteReminderUseCase', (tester) async {
    await tester.pumpWidget(buildSubject(buildReminder(id: 5)));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    verify(() => mockDelete.call(id: 5, notificationId: 100)).called(1);
  });

  testWidgets('id 為 null 時刪除按鈕停用', (tester) async {
    await tester.pumpWidget(buildSubject(buildReminder(id: null)));
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_outline),
    );
    expect(button.onPressed, isNull);
  });
}
