import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/constants/app_colors.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/constants/home_ui_colors.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    required this.title,
    required this.action,
    super.key,
    this.onActionTap,
  });

  final String title;
  final String action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              action,
              style: const TextStyle(
                color: HomeUiColors.accent,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
