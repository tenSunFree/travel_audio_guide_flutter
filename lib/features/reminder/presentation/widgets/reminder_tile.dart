import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/features/reminder/di/reminder_providers.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:go_router/go_router.dart';

class ReminderTile extends ConsumerWidget {
  const ReminderTile({required this.reminder, super.key});

  final Reminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expired = reminder.isExpired;
    return Card(
      child: ListTile(
        leading: Icon(expired ? Icons.event_busy : Icons.notifications_active),
        title: Text(
          reminder.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('提醒：${_formatDateTime(reminder.notifyTime)}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: reminder.id == null
              ? null
              : () async {
                  await ref
                      .read(deleteReminderUseCaseProvider)
                      .call(
                        id: reminder.id!,
                        notificationId: reminder.notificationId,
                      );
                },
        ),
        onTap: expired ? null : () => context.push(reminder.routePath),
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    return '${time.year}/'
        '${time.month.toString().padLeft(2, '0')}/'
        '${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
