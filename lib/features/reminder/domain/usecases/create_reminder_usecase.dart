import 'dart:convert';
import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/repositories/reminder_repository.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/services/notification_service.dart';

class CreateReminderUseCase {
  CreateReminderUseCase(this._repository, this._notificationService);

  final ReminderRepository _repository;
  final NotificationService _notificationService;

  Future<void> call(CreateReminderParams params) async {
    final notifyTime = params.targetTime.subtract(
      Duration(seconds: params.remindBeforeSeconds),
    );
    if (notifyTime.isBefore(DateTime.now())) {
      throw Exception('提醒時間已經過了，請重新設定');
    }
    final notificationId = Object.hash(
      params.sourceType,
      params.sourceId,
      notifyTime.millisecondsSinceEpoch,
    ).abs();
    final routePath = _buildRoutePath(params.sourceType, params.sourceId);
    final payloadJson = jsonEncode({
      'sourceType': params.sourceType,
      'sourceId': params.sourceId,
      'routePath': routePath,
      'notificationId': notificationId,
    });
    final reminder = Reminder(
      sourceType: params.sourceType,
      sourceId: params.sourceId,
      title: params.title,
      subtitle: params.subtitle,
      imageUrl: params.imageUrl,
      address: params.address,
      targetTime: params.targetTime,
      remindBeforeSeconds: params.remindBeforeSeconds,
      notifyTime: notifyTime,
      notificationId: notificationId,
      routePath: routePath,
      payloadJson: payloadJson,
      isEnabled: true,
      isDone: false,
      createdAt: DateTime.now(),
    );
    final savedReminder = await _repository.createReminder(reminder);
    try {
      await _notificationService.scheduleReminder(savedReminder);
    } catch (e) {
      if (savedReminder.id != null) {
        await _repository.deleteReminder(savedReminder.id!);
      }
      rethrow;
    }
  }

  String _buildRoutePath(String sourceType, String sourceId) {
    return switch (sourceType) {
      'attraction' => '/attractions/$sourceId',
      'activity' => '/activities/$sourceId',
      'audioGuide' => '/audio-guides/$sourceId',
      _ => throw Exception('不支援的 sourceType：$sourceType'),
    };
  }
}

class CreateReminderParams {
  const CreateReminderParams({
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.targetTime,
    required this.remindBeforeSeconds,
    this.subtitle,
    this.imageUrl,
    this.address,
  });

  final String sourceType;
  final String sourceId;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? address;
  final DateTime targetTime;
  final int remindBeforeSeconds;
}
