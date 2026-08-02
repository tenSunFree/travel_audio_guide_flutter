import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';

abstract class ReminderRepository {
  Stream<List<Reminder>> watchAllReminders();

  Future<List<Reminder>> getPendingEnabledReminders();

  Future<Reminder> createReminder(Reminder reminder);

  Future<void> deleteReminder(int id);
}
