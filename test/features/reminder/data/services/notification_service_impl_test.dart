import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/reminder/data/services/notification_service_impl.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class MockIOSFlutterLocalNotificationsPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

class _FakeInitializationSettings extends Fake
    implements InitializationSettings {}

class _FakeNotificationDetails extends Fake implements NotificationDetails {}

class _FakeTZDateTime extends Fake implements tz.TZDateTime {}

void main() {
  late MockFlutterLocalNotificationsPlugin plugin;
  late MockAndroidFlutterLocalNotificationsPlugin androidPlugin;
  late MockIOSFlutterLocalNotificationsPlugin iosPlugin;
  late NotificationServiceImpl service;

  setUpAll(() {
    registerFallbackValue(_FakeInitializationSettings());
    registerFallbackValue(_FakeNotificationDetails());
    registerFallbackValue(_FakeTZDateTime());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  setUp(() {
    plugin = MockFlutterLocalNotificationsPlugin();
    androidPlugin = MockAndroidFlutterLocalNotificationsPlugin();
    iosPlugin = MockIOSFlutterLocalNotificationsPlugin();
    service = NotificationServiceImpl(plugin);
    when(
      () => plugin.initialize(settings: any(named: 'settings')),
    ).thenAnswer((_) async => true);
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(androidPlugin);
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(iosPlugin);
    when(
      () => androidPlugin.canScheduleExactNotifications(),
    ).thenAnswer((_) async => true);
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
  });

  Reminder buildReminder({
    required DateTime notifyTime,
    int id = 1,
    String title = '測試提醒',
    int remindBeforeSeconds = 3600,
    int notificationId = 100,
    bool isEnabled = true,
    bool isDone = false,
  }) {
    final now = DateTime.now();
    return Reminder(
      id: id,
      sourceType: 'attraction',
      sourceId: 'A001',
      title: title,
      targetTime: notifyTime.add(Duration(seconds: remindBeforeSeconds)),
      remindBeforeSeconds: remindBeforeSeconds,
      notifyTime: notifyTime,
      notificationId: notificationId,
      routePath: '/attractions/A001',
      payloadJson: '{"sourceId":"A001"}',
      isEnabled: isEnabled,
      isDone: isDone,
      createdAt: now,
    );
  }

  group('NotificationServiceImpl.initialize', () {
    test('會呼叫 plugin.initialize，且重複呼叫只會真正初始化一次', () async {
      await service.initialize();
      await service.initialize();
      verify(
        () => plugin.initialize(settings: any(named: 'settings')),
      ).called(1);
    });
  });

  group('NotificationServiceImpl.requestPermission', () {
    test('Android 有結果時，直接回傳 Android 的授權結果', () async {
      when(
        () => androidPlugin.requestNotificationsPermission(),
      ).thenAnswer((_) async => true);
      when(
        () =>
            iosPlugin.requestPermissions(alert: true, badge: true, sound: true),
      ).thenAnswer((_) async => false);
      final result = await service.requestPermission();
      expect(result, isTrue);
    });

    test('Android 回傳 null（例如非 Android 平台）時，改用 iOS 的授權結果', () async {
      when(
        () => androidPlugin.requestNotificationsPermission(),
      ).thenAnswer((_) async => null);
      when(
        () =>
            iosPlugin.requestPermissions(alert: true, badge: true, sound: true),
      ).thenAnswer((_) async => true);
      final result = await service.requestPermission();
      expect(result, isTrue);
    });

    test('Android / iOS 都沒有結果時，預設視為已授權', () async {
      when(
        () => androidPlugin.requestNotificationsPermission(),
      ).thenAnswer((_) async => null);
      when(
        () =>
            iosPlugin.requestPermissions(alert: true, badge: true, sound: true),
      ).thenAnswer((_) async => null);
      final result = await service.requestPermission();
      expect(result, isTrue);
    });
  });

  group('NotificationServiceImpl.scheduleReminder', () {
    test('notifyTime 已過期時，不會呼叫 zonedSchedule', () async {
      final reminder = buildReminder(
        notifyTime: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      await service.scheduleReminder(reminder);
      verifyNever(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('notifyTime 是未來時間時，會排程通知，且標題/內容/payload 正確', () async {
      final reminder = buildReminder(
        title: '陽明山健行',
        notifyTime: DateTime.now().add(const Duration(hours: 1)),
        remindBeforeSeconds: 3661, // 1 hour 1 minute 1 second
        notificationId: 42,
      );
      await service.scheduleReminder(reminder);
      final captured = verify(
        () => plugin.zonedSchedule(
          id: captureAny(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: captureAny(named: 'title'),
          body: captureAny(named: 'body'),
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured[0], 42); // id
      expect(captured[1], '行程提醒：陽明山健行'); // title
      expect(captured[2], '您設定的行程將於 1 小時1 分鐘1 秒 後開始'); // body
      expect(captured[3], '{"sourceId":"A001"}'); // payload
    });

    test('remindBeforeSeconds 為 0 時，內容顯示「時間到了」', () async {
      final reminder = buildReminder(
        notifyTime: DateTime.now().add(const Duration(hours: 1)),
        remindBeforeSeconds: 0,
      );
      await service.scheduleReminder(reminder);
      final captured = verify(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: captureAny(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).captured;
      expect(captured.single, '您設定的行程時間到了');
    });

    test('可以排定精確鬧鐘時，使用 exactAllowWhileIdle 排程模式', () async {
      when(
        () => androidPlugin.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);
      final reminder = buildReminder(
        notifyTime: DateTime.now().add(const Duration(hours: 1)),
      );
      await service.scheduleReminder(reminder);
      final captured = verify(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: captureAny(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).captured;
      expect(captured.single, AndroidScheduleMode.exactAllowWhileIdle);
    });

    test('不能排定精確鬧鐘時，改用 inexactAllowWhileIdle 排程模式', () async {
      when(
        () => androidPlugin.canScheduleExactNotifications(),
      ).thenAnswer((_) async => false);
      final reminder = buildReminder(
        notifyTime: DateTime.now().add(const Duration(hours: 1)),
      );
      await service.scheduleReminder(reminder);
      final captured = verify(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: captureAny(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).captured;
      expect(captured.single, AndroidScheduleMode.inexactAllowWhileIdle);
    });

    test('查詢是否可排定精確鬧鐘時發生例外，也會安全地退回 inexact 模式', () async {
      when(
        () => androidPlugin.canScheduleExactNotifications(),
      ).thenThrow(Exception('查詢失敗'));
      final reminder = buildReminder(
        notifyTime: DateTime.now().add(const Duration(hours: 1)),
      );
      await service.scheduleReminder(reminder);
      final captured = verify(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: captureAny(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).captured;
      expect(captured.single, AndroidScheduleMode.inexactAllowWhileIdle);
    });
  });

  group('NotificationServiceImpl.cancelReminder', () {
    test('會用正確的 notificationId 呼叫 plugin.cancel', () async {
      await service.cancelReminder(99);
      verify(() => plugin.cancel(id: 99)).called(1);
    });
  });

  group('NotificationServiceImpl.reschedulePendingReminders', () {
    test('只有未過期、未啟用完成、且啟用中的提醒會被重新排程', () async {
      final now = DateTime.now();
      final valid = buildReminder(
        notifyTime: now.add(const Duration(hours: 1)),
      );
      final expired = buildReminder(
        id: 2,
        notifyTime: now.subtract(const Duration(hours: 1)),
      );
      final done = buildReminder(
        id: 3,
        notifyTime: now.add(const Duration(hours: 1)),
        isDone: true,
      );
      final disabled = buildReminder(
        id: 4,
        notifyTime: now.add(const Duration(hours: 1)),
        isEnabled: false,
      );
      await service.reschedulePendingReminders([
        valid,
        expired,
        done,
        disabled,
      ]);
      final captured = verify(
        () => plugin.zonedSchedule(
          id: captureAny(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).captured;
      expect(captured, [100]); // only the valid reminder's notificationId
    });
  });
}
