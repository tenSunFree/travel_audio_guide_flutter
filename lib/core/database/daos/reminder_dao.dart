import 'package:drift/drift.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/tables/reminder_table.dart';

part 'reminder_dao.g.dart';

@DriftAccessor(tables: [ReminderTable])
class ReminderDao extends DatabaseAccessor<AppDatabase>
    with _$ReminderDaoMixin {
  ReminderDao(super.db);

  Stream<List<ReminderTableData>> watchAllReminders() {
    return (select(reminderTable)..orderBy([
          (t) => OrderingTerm(expression: t.notifyTime),
        ]))
        .watch();
  }

  Future<List<ReminderTableData>> getPendingEnabledReminders(DateTime now) {
    return (select(reminderTable)
          ..where(
            (t) =>
                t.isEnabled.equals(true) &
                t.isDone.equals(false) &
                t.notifyTime.isBiggerThanValue(now),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.notifyTime),
          ]))
        .get();
  }

  Future<int> insertReminder(ReminderTableCompanion companion) {
    return into(reminderTable).insert(companion);
  }

  Future<int> deleteReminderById(int id) {
    return (delete(reminderTable)..where((t) => t.id.equals(id))).go();
  }
}
