import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/features/reminder/di/reminder_providers.dart';
import 'package:flutter_travel_audio_guide/features/reminder/data/repositories/reminder_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/reminder/data/services/notification_service_impl.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/usecases/create_reminder_usecase.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/usecases/delete_reminder_usecase.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/usecases/reschedule_pending_reminders_usecase.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(MockAppDatabase())],
    );
  });

  tearDown(() => container.dispose());

  test('flutterLocalNotificationsPluginProvider 建立實例', () {
    final plugin = container.read(flutterLocalNotificationsPluginProvider);
    expect(plugin, isNotNull);
  });

  test('notificationServiceProvider 回傳 NotificationServiceImpl', () {
    final service = container.read(notificationServiceProvider);
    expect(service, isA<NotificationServiceImpl>());
  });

  test('reminderRepositoryProvider 回傳 ReminderRepositoryImpl', () {
    final repo = container.read(reminderRepositoryProvider);
    expect(repo, isA<ReminderRepositoryImpl>());
  });

  test('createReminderUseCaseProvider 正確組裝依賴', () {
    final usecase = container.read(createReminderUseCaseProvider);
    expect(usecase, isA<CreateReminderUseCase>());
  });

  test('deleteReminderUseCaseProvider 正確組裝依賴', () {
    final usecase = container.read(deleteReminderUseCaseProvider);
    expect(usecase, isA<DeleteReminderUseCase>());
  });

  test('reschedulePendingRemindersUseCaseProvider 正確組裝依賴', () {
    final usecase = container.read(reschedulePendingRemindersUseCaseProvider);
    expect(usecase, isA<ReschedulePendingRemindersUseCase>());
  });
}
