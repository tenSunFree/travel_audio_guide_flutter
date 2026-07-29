import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/activity.dart';

class ActivityLinkRow extends StatelessWidget {
  const ActivityLinkRow({super.key, required this.link, required this.onTap});

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
            Icon(Icons.link, size: 16, color: AppColors.textCaption),
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
