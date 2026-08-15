import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide_page.dart';

abstract class AudioGuideRepository {
  Future<AudioGuidePage> getAudioGuides({
    required String lang,
    required int page,
  });

  Future<String> downloadAudioGuide(AudioGuide guide);

  Future<bool> isGuideDownloaded(AudioGuide guide);
}
