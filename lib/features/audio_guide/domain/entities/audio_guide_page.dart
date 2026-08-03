import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_guide_page.freezed.dart';

@freezed
abstract class AudioGuidePage with _$AudioGuidePage {
  const factory AudioGuidePage({
    required int total,
    required int page,
    required List<AudioGuide> items,
    required bool hasMore,
  }) = _AudioGuidePage;
}
