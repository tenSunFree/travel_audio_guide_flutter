import 'package:drift/drift.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/tables/sync_meta_table.dart';

part 'sync_meta_dao.g.dart';

@DriftAccessor(tables: [SyncMetaTable])
class SyncMetaDao extends DatabaseAccessor<AppDatabase>
    with _$SyncMetaDaoMixin {
  SyncMetaDao(super.db);

  Future<DateTime?> getLastSyncedAt(String key) async {
    final row = await (select(
      syncMetaTable,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.lastSyncedAt;
  }

  Future<void> saveLastSyncedAt(String key) async {
    await into(syncMetaTable).insertOnConflictUpdate(
      SyncMetaTableCompanion.insert(key: key, lastSyncedAt: DateTime.now()),
    );
  }
}
