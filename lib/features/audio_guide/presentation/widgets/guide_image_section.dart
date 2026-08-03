import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/constants/app_colors.dart';
import 'package:flutter_travel_audio_guide/core/widgets/app_cached_network_image.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';

class GuideImageSection extends StatefulWidget {
  const GuideImageSection({required this.attraction, super.key});

  final Attraction? attraction;

  @override
  State<GuideImageSection> createState() => _GuideImageSectionState();
}

class _GuideImageSectionState extends State<GuideImageSection> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.attraction?.images ?? const <AttractionImage>[];
    if (images.isEmpty) {
      return Container(
        height: 200,
        color: AppColors.surfaceMuted,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.headphones_outlined,
              size: 52,
              color: AppColors.textHint,
            ),
            SizedBox(height: 8),
            Text(
              '語音導覽',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          ],
        ),
      );
    }
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return AppCachedNetworkImage(
                    imageUrl: images[i].src,
                    width: constraints.maxWidth,
                    height: 200,
                    errorWidget: Container(
                      color: AppColors.surfaceMuted,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: AppColors.textHint,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1} / ${images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
