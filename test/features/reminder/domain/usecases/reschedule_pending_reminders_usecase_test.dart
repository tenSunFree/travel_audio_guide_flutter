import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/repositories/reminder_repository.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/services/notification_service.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/usecases/reschedule_pending_reminders_usecase.dart';

class MockReminderRepository extends Mock implements ReminderRepository {}

class MockNotificationService extends Mock implements NotificationService {}

Reminder _buildReminder(int id) {
  final now = DateTime.now();
  return Reminder(
    id: id,
    sourceType: 'attraction',
    sourceId: 'A00$id',
    title: '提醒 $id',
    targetTime: now.add(const Duration(days: 1)),
    remindBeforeSeconds: 3600,
    notifyTime: now.add(const Duration(hours: 23)),
    notificationId: id,
    routePath: '/attractions/A00$id',
    payloadJson: '{}',
    isEnabled: true,
    isDone: false,
    createdAt: now,
  );
}

void main() {
  late MockReminderRepository repository;
  late MockNotificationService notificationService;
  late ReschedulePendingRemindersUseCase useCase;

  setUp(() {
    repository = MockReminderRepository();
    notificationService = MockNotificationService();
    useCase = ReschedulePendingRemindersUseCase(
      repository,
      notificationService,
    );
  });

  group('ReschedulePendingRemindersUseCase', () {
    test('會取得待處理提醒清單，並交給 notificationService 重新排程', () async {
      final reminders = [_buildReminder(1), _buildReminder(2)];
      when(
        () => repository.getPendingEnabledReminders(),
      ).thenAnswer((_) async => reminders);
      when(
        () => notificationService.reschedulePendingReminders(any()),
      ).thenAnswer((_) async {});
      await useCase();
      verify(() => repository.getPendingEnabledReminders()).called(1);
      verify(
        () => notificationService.reschedulePendingReminders(reminders),
      ).called(1);
    });

    test('沒有待處理提醒時，仍會呼叫 reschedulePendingReminders(空清單)', () async {
      when(
        () => repository.getPendingEnabledReminders(),
      ).thenAnswer((_) async => []);
      when(
        () => notificationService.reschedulePendingReminders(any()),
      ).thenAnswer((_) async {});
      await useCase();
      verify(
        () => notificationService.reschedulePendingReminders([]),
      ).called(1);
    });

    test('repository 拋出例外時，useCase 會向外拋出', () async {
      when(
        () => repository.getPendingEnabledReminders(),
      ).thenThrow(Exception('db error'));
      await expectLater(useCase(), throwsA(isA<Exception>()));
      verifyNever(() => notificationService.reschedulePendingReminders(any()));
    });
  });
}
