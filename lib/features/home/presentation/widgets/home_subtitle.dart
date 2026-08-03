import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/constants/app_colors.dart';

class HomeSubtitle extends StatelessWidget {
  const HomeSubtitle({required this.subtitle, super.key});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }
}
