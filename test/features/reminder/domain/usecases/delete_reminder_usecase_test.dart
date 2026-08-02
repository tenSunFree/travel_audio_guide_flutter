import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/repositories/reminder_repository.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/services/notification_service.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/usecases/delete_reminder_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockReminderRepository extends Mock implements ReminderRepository {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockReminderRepository repository;
  late MockNotificationService notificationService;
  late DeleteReminderUseCase useCase;

  setUp(() {
    repository = MockReminderRepository();
    notificationService = MockNotificationService();
    useCase = DeleteReminderUseCase(repository, notificationService);
  });

  group('DeleteReminderUseCase', () {
    test('會先取消通知，再刪除提醒（依序執行）', () async {
      when(
        () => notificationService.cancelReminder(any()),
      ).thenAnswer((_) async {});
      when(() => repository.deleteReminder(any())).thenAnswer((_) async {});
      await useCase(id: 1, notificationId: 100);
      verifyInOrder([
        () => notificationService.cancelReminder(100),
        () => repository.deleteReminder(1),
      ]);
      verifyNoMoreInteractions(notificationService);
      verifyNoMoreInteractions(repository);
    });

    test('取消通知失敗時應該向外拋出例外，且不會刪除提醒', () async {
      when(
        () => notificationService.cancelReminder(any()),
      ).thenThrow(Exception('cancel failed'));
      await expectLater(
        useCase(id: 1, notificationId: 100),
        throwsA(isA<Exception>()),
      );
      verifyNever(() => repository.deleteReminder(any()));
    });

    test('repository.deleteReminder 失敗時會向外拋出例外', () async {
      when(
        () => notificationService.cancelReminder(any()),
      ).thenAnswer((_) async {});
      when(
        () => repository.deleteReminder(any()),
      ).thenThrow(Exception('delete failed'));
      await expectLater(
        useCase(id: 1, notificationId: 100),
        throwsA(isA<Exception>()),
      );
    });
  });
}
