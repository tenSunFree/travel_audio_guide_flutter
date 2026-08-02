import 'package:flutter_travel_audio_guide/features/reminder/domain/repositories/reminder_repository.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/services/notification_service.dart';

class ReschedulePendingRemindersUseCase {
  ReschedulePendingRemindersUseCase(
    this._repository,
    this._notificationService,
  );

  final ReminderRepository _repository;
  final NotificationService _notificationService;

  Future<void> call() async {
    final reminders = await _repository.getPendingEnabledReminders();
    await _notificationService.reschedulePendingReminders(reminders);
  }
}
