import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/constants/app_colors.dart';

class StepCountBadge extends StatelessWidget {
  const StepCountBadge({
    required this.steps,
    required this.distance,
    super.key,
  });

  final int steps;
  final double distance;

  @override
  Widget build(BuildContext context) {
    final label = distance < 1000
        ? '${distance.toStringAsFixed(0)} 公尺'
        : '${(distance / 1000).toStringAsFixed(1)} 公里';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚶', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(
            '$steps 步 · $label',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
