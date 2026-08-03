import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/constants/app_colors.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_playback_state.dart';

class PlaybackCard extends StatelessWidget {
  const PlaybackCard({
    required this.title,
    required this.playerState,
    required this.onTogglePlayPause,
    required this.onSeek,
    super.key,
  });

  final String title;
  final AudioPlaybackState playerState;
  final VoidCallback? onTogglePlayPause;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final durationMs = playerState.duration.inMilliseconds;
    final posMs = playerState.position.inMilliseconds.clamp(0, durationMs);
    final isReady = playerState.isReady;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: onTogglePlayPause,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isReady
                        ? colorScheme.primary
                        : AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: playerState.isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Icon(
                          playerState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 30,
                          color: isReady
                              ? colorScheme.onPrimary
                              : AppColors.iconPrimary,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmt(playerState.position),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textCaption,
                          ),
                        ),
                        Text(
                          _fmt(playerState.duration),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textCaption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (durationMs > 0)
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                        ),
                        child: Slider(
                          value: posMs.toDouble(),
                          max: durationMs.toDouble(),
                          onChanged: (v) =>
                              onSeek(Duration(milliseconds: v.toInt())),
                        ),
                      )
                    else
                      const SizedBox(
                        height: 20,
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (playerState.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              playerState.errorMessage!,
              style: const TextStyle(color: AppColors.textError, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }
}
