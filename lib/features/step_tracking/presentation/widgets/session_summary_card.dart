import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/constants/app_colors.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/domain/entities/exercise_summary_data.dart';

class SessionSummaryCard extends StatelessWidget {
  const SessionSummaryCard({required this.summary, super.key});

  final ExerciseSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final dur = summary.duration;
    final minutes = dur.inMinutes;
    final seconds = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    // Show meters below 1 km; switch to kilometres once the threshold is crossed.
    final distanceLabel = summary.distanceMeters < 1000
        ? '${summary.distanceMeters.toStringAsFixed(0)} 公尺'
        : '${(summary.distanceMeters / 1000).toStringAsFixed(1)} 公里';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            summary.guideName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text('導覽完成', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                icon: Icons.timer_outlined,
                label: '時長',
                value: '$minutes:$seconds',
              ),
              _StatItem(
                icon: Icons.directions_walk_rounded,
                label: '步數',
                value: '${summary.steps}',
              ),
              _StatItem(
                icon: Icons.straighten_rounded,
                label: '距離',
                value: distanceLabel,
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.iconPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('完成', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: AppColors.iconPrimary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}
