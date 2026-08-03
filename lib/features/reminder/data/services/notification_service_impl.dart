import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationServiceImpl implements NotificationService {
  NotificationServiceImpl(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initTimezone();
    _initialized = true;
  }

  void _initTimezone() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Taipei'));
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await androidPlugin
        ?.requestNotificationsPermission();
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidGranted ?? iosGranted ?? true;
  }

  @override
  Future<void> scheduleReminder(Reminder reminder) async {
    await initialize();
    final scheduledDate = tz.TZDateTime.from(reminder.notifyTime, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;
    // Dynamically decide the scheduling mode to avoid exact_alarms_not_permitted crash
    final scheduleMode = await _resolveScheduleMode();
    await _plugin.zonedSchedule(
      id: reminder.notificationId,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'travel_reminder_channel',
          '旅遊提醒',
          channelDescription: '提醒即將到來的景點、活動或語音導覽',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode,
      title: '行程提醒：${reminder.title}',
      body: _buildBody(reminder),
      payload: reminder.payloadJson,
    );
  }

  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canExact = await androidPlugin?.canScheduleExactNotifications();
      if (canExact == true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (e) {
      debugPrint('canScheduleExactNotifications query failed: $e');
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  String _buildBody(Reminder reminder) {
    if (reminder.remindBeforeSeconds == 0) return '您設定的行程時間到了';
    final h = reminder.remindBeforeSeconds ~/ 3600;
    final m = (reminder.remindBeforeSeconds % 3600) ~/ 60;
    final s = reminder.remindBeforeSeconds % 60;
    final parts = [if (h > 0) '$h 小時', if (m > 0) '$m 分鐘', if (s > 0) '$s 秒'];
    return '您設定的行程將於 ${parts.join()} 後開始';
  }

  @override
  Future<void> cancelReminder(int notificationId) {
    return _plugin.cancel(id: notificationId);
  }

  @override
  Future<void> reschedulePendingReminders(List<Reminder> reminders) async {
    await initialize();
    for (final reminder in reminders) {
      if (!reminder.isExpired && !reminder.isDone && reminder.isEnabled) {
        await scheduleReminder(reminder);
      }
    }
  }
}
