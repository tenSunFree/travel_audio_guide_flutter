import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/features/reminder/data/repositories/reminder_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/reminder/data/services/notification_service_impl.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/repositories/reminder_repository.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/services/notification_service.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/usecases/create_reminder_usecase.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/usecases/delete_reminder_usecase.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/usecases/reschedule_pending_reminders_usecase.dart';

final flutterLocalNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationServiceImpl(
    ref.watch(flutterLocalNotificationsPluginProvider),
  );
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl(ref.watch(appDatabaseProvider));
});

final createReminderUseCaseProvider = Provider<CreateReminderUseCase>((ref) {
  return CreateReminderUseCase(
    ref.watch(reminderRepositoryProvider),
    ref.watch(notificationServiceProvider),
  );
});

final deleteReminderUseCaseProvider = Provider<DeleteReminderUseCase>((ref) {
  return DeleteReminderUseCase(
    ref.watch(reminderRepositoryProvider),
    ref.watch(notificationServiceProvider),
  );
});

final reschedulePendingRemindersUseCaseProvider =
    Provider<ReschedulePendingRemindersUseCase>((ref) {
      return ReschedulePendingRemindersUseCase(
        ref.watch(reminderRepositoryProvider),
        ref.watch(notificationServiceProvider),
      );
    });

final reminderListProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(reminderRepositoryProvider).watchAllReminders();
});
