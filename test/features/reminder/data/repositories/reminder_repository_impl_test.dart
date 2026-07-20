import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:flutter_travel_audio_guide/features/reminder/data/repositories/reminder_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ReminderRepositoryImpl repository;

  setUp(() {
    // Follow the convention from test/test_helpers/app_test_harness.dart:
    // Use an in-memory SQLite database to test the integration between the
    // Repository and Drift DAOs directly. Avoid mocking the generated
    // DatabaseAccessor mixin (mocking that tends to be more fragile).
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ReminderRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  Reminder buildReminder({
    required String sourceId,
    String sourceType = 'attraction',
    Duration notifyOffset = const Duration(hours: 1),
    bool isEnabled = true,
    bool isDone = false,
  }) {
    final now = DateTime.now();
    final targetTime = now.add(notifyOffset + const Duration(hours: 1));
    return Reminder(
      id: null,
      sourceType: sourceType,
      sourceId: sourceId,
      title: '提醒 $sourceId',
      subtitle: '副標 $sourceId',
      imageUrl: 'https://example.com/$sourceId.png',
      address: '台北市信義區',
      targetTime: targetTime,
      remindBeforeSeconds: 3600,
      notifyTime: now.add(notifyOffset),
      notificationId: sourceId.hashCode.abs(),
      routePath: '/$sourceType/$sourceId',
      payloadJson: '{"sourceId":"$sourceId"}',
      isEnabled: isEnabled,
      isDone: isDone,
      createdAt: now,
      updatedAt: null,
    );
  }

  group('ReminderRepositoryImpl.createReminder', () {
    test('寫入後回傳帶有自動產生 id 的 Reminder，且欄位正確映射', () async {
      final input = buildReminder(sourceId: 'A001');
      final saved = await repository.createReminder(input);
      expect(saved.id, isNotNull);
      expect(saved.sourceType, input.sourceType);
      expect(saved.sourceId, 'A001');
      expect(saved.title, input.title);
      expect(saved.subtitle, input.subtitle);
      expect(saved.imageUrl, input.imageUrl);
      expect(saved.address, input.address);
      expect(saved.remindBeforeSeconds, 3600);
      expect(saved.notificationId, input.notificationId);
      expect(saved.routePath, input.routePath);
      expect(saved.payloadJson, input.payloadJson);
      expect(saved.isEnabled, isTrue);
      expect(saved.isDone, isFalse);
    });

    test('subtitle / imageUrl / address 為 null 時也能正確寫入與讀出', () async {
      final now = DateTime.now();
      final input = Reminder(
        id: null,
        sourceType: 'activity',
        sourceId: 'B001',
        title: '無副標提醒',
        subtitle: null,
        imageUrl: null,
        address: null,
        targetTime: now.add(const Duration(hours: 2)),
        remindBeforeSeconds: 1800,
        notifyTime: now.add(const Duration(hours: 1)),
        notificationId: 999,
        routePath: '/activities/B001',
        payloadJson: '{}',
        isEnabled: true,
        isDone: false,
        createdAt: now,
      );
      final saved = await repository.createReminder(input);
      expect(saved.subtitle, isNull);
      expect(saved.imageUrl, isNull);
      expect(saved.address, isNull);
    });
  });

  group('ReminderRepositoryImpl.watchAllReminders', () {
    test('依 notifyTime 由近到遠升冪排序', () async {
      await repository.createReminder(
        buildReminder(sourceId: 'late', notifyOffset: const Duration(hours: 5)),
      );
      await repository.createReminder(
        buildReminder(
          sourceId: 'soon',
          notifyOffset: const Duration(minutes: 10),
        ),
      );
      await repository.createReminder(
        buildReminder(sourceId: 'mid', notifyOffset: const Duration(hours: 2)),
      );
      final list = await repository.watchAllReminders().first;
      expect(list.map((r) => r.sourceId).toList(), ['soon', 'mid', 'late']);
    });

    test('沒有任何提醒時回傳空清單', () async {
      final list = await repository.watchAllReminders().first;
      expect(list, isEmpty);
    });
  });

  group('ReminderRepositoryImpl.getPendingEnabledReminders', () {
    test('只回傳尚未到期、啟用中、且未完成的提醒', () async {
      await repository.createReminder(
        buildReminder(
          sourceId: 'pending',
          notifyOffset: const Duration(hours: 1),
        ),
      );
      await repository.createReminder(
        buildReminder(
          sourceId: 'disabled',
          notifyOffset: const Duration(hours: 1),
          isEnabled: false,
        ),
      );
      await repository.createReminder(
        buildReminder(
          sourceId: 'done',
          notifyOffset: const Duration(hours: 1),
          isDone: true,
        ),
      );
      await repository.createReminder(
        buildReminder(
          sourceId: 'expired',
          notifyOffset: const Duration(minutes: -30),
        ),
      );
      final result = await repository.getPendingEnabledReminders();
      expect(result.map((r) => r.sourceId).toList(), ['pending']);
    });

    test('沒有符合條件的提醒時回傳空清單', () async {
      await repository.createReminder(
        buildReminder(sourceId: 'disabled', isEnabled: false),
      );
      final result = await repository.getPendingEnabledReminders();
      expect(result, isEmpty);
    });
  });

  group('ReminderRepositoryImpl.deleteReminder', () {
    test('刪除後該筆提醒不再出現於任何查詢結果', () async {
      final saved = await repository.createReminder(
        buildReminder(sourceId: 'to-delete'),
      );
      await repository.deleteReminder(saved.id!);
      final all = await repository.watchAllReminders().first;
      expect(all, isEmpty);
      final pending = await repository.getPendingEnabledReminders();
      expect(pending, isEmpty);
    });

    test('刪除不存在的 id 不會拋出例外', () async {
      await expectLater(repository.deleteReminder(999999), completes);
    });
  });
}
