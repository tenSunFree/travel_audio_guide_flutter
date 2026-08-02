import 'package:drift/drift.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/repositories/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Reminder>> watchAllReminders() {
    return _db.reminderDao.watchAllReminders().map(
      (rows) => rows.map(_toEntity).toList(),
    );
  }

  @override
  Future<List<Reminder>> getPendingEnabledReminders() async {
    final rows = await _db.reminderDao.getPendingEnabledReminders(
      DateTime.now(),
    );
    return rows.map(_toEntity).toList();
  }

  @override
  Future<Reminder> createReminder(Reminder reminder) async {
    final id = await _db.reminderDao.insertReminder(
      ReminderTableCompanion.insert(
        sourceType: reminder.sourceType,
        sourceId: reminder.sourceId,
        title: reminder.title,
        subtitle: Value(reminder.subtitle),
        imageUrl: Value(reminder.imageUrl),
        address: Value(reminder.address),
        targetTime: reminder.targetTime,
        remindBeforeSeconds: Value(reminder.remindBeforeSeconds),
        notifyTime: reminder.notifyTime,
        notificationId: reminder.notificationId,
        routePath: reminder.routePath,
        payloadJson: reminder.payloadJson,
        isEnabled: Value(reminder.isEnabled),
        isDone: Value(reminder.isDone),
        createdAt: reminder.createdAt,
        updatedAt: Value(reminder.updatedAt),
      ),
    );
    return Reminder(
      id: id,
      sourceType: reminder.sourceType,
      sourceId: reminder.sourceId,
      title: reminder.title,
      subtitle: reminder.subtitle,
      imageUrl: reminder.imageUrl,
      address: reminder.address,
      targetTime: reminder.targetTime,
      remindBeforeSeconds: reminder.remindBeforeSeconds,
      notifyTime: reminder.notifyTime,
      notificationId: reminder.notificationId,
      routePath: reminder.routePath,
      payloadJson: reminder.payloadJson,
      isEnabled: reminder.isEnabled,
      isDone: reminder.isDone,
      createdAt: reminder.createdAt,
      updatedAt: reminder.updatedAt,
    );
  }

  @override
  Future<void> deleteReminder(int id) async {
    await _db.reminderDao.deleteReminderById(id);
  }

  Reminder _toEntity(ReminderTableData row) {
    return Reminder(
      id: row.id,
      sourceType: row.sourceType,
      sourceId: row.sourceId,
      title: row.title,
      subtitle: row.subtitle,
      imageUrl: row.imageUrl,
      address: row.address,
      targetTime: row.targetTime,
      remindBeforeSeconds: row.remindBeforeSeconds,
      notifyTime: row.notifyTime,
      notificationId: row.notificationId,
      routePath: row.routePath,
      payloadJson: row.payloadJson,
      isEnabled: row.isEnabled,
      isDone: row.isDone,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
