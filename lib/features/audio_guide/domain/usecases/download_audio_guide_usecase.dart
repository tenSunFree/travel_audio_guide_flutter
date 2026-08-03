import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/repositories/audio_guide_repository.dart';

class DownloadAudioGuideUseCase {
  const DownloadAudioGuideUseCase(this._repository);

  final AudioGuideRepository _repository;

  Future<String> call(AudioGuide guide) {
    return _repository.downloadAudioGuide(guide);
  }
}
