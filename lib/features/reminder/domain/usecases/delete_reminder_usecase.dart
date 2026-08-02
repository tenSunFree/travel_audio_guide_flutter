import 'package:flutter_travel_audio_guide/features/reminder/domain/repositories/reminder_repository.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/services/notification_service.dart';

class DeleteReminderUseCase {
  DeleteReminderUseCase(this._repository, this._notificationService);

  final ReminderRepository _repository;
  final NotificationService _notificationService;

  Future<void> call({required int id, required int notificationId}) async {
    await _notificationService.cancelReminder(notificationId);
    await _repository.deleteReminder(id);
  }
}
