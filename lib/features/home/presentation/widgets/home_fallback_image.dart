import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/constants/app_colors.dart';

/// A backup block of emojis to display when an image fails to load.
class HomeFallbackImage extends StatelessWidget {
  const HomeFallbackImage(this.emoji, {super.key});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 34)),
    );
  }
}
