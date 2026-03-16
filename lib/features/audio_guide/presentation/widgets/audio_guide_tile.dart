import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/audio_guide.dart';

class AudioGuideTile extends StatelessWidget {
  const AudioGuideTile({
    super.key,
    required this.guide,
    required this.isDownloading,
    required this.onActionPressed,
  });

  final AudioGuide guide;
  final bool isDownloading;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    final showPlay = guide.isDownloaded;

    return Container(
      height: 84,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              guide.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 92,
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: isDownloading ? null : onActionPressed,
                  icon: isDownloading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          showPlay
                              ? Icons.play_arrow_rounded
                              : Icons.download_rounded,
                          size: 16,
                        ),
                  label: Text(isDownloading ? '下載中' : (showPlay ? '播放' : '下載')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textSecondary,
                    textStyle: const TextStyle(fontSize: 13),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                guide.modified,
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
