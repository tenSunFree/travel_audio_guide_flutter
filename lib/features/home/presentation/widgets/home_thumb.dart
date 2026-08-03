import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/widgets/app_cached_network_image.dart';
import 'package:flutter_travel_audio_guide/features/home/domain/entities/home_state.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/widgets/home_fallback_image.dart';

/// List thumbnails 96×96
class HomeThumb extends StatelessWidget {
  const HomeThumb({required this.card, super.key});

  final HomeRecommendCard card;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 96,
        height: 96,
        child: card.imageUrl != null
            ? AppCachedNetworkImage(
                imageUrl: card.imageUrl!,
                width: 96,
                height: 96,
                errorWidget: HomeFallbackImage(card.emoji),
              )
            : HomeFallbackImage(card.emoji),
      ),
    );
  }
}
