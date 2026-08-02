import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/constants/app_colors.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity.dart';

class ActivityLinkRow extends StatelessWidget {
  const ActivityLinkRow({required this.link, required this.onTap, super.key});

  final ActivityLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = link.subject.isNotEmpty ? link.subject : link.src;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            const Icon(Icons.link, size: 16, color: AppColors.textCaption),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
