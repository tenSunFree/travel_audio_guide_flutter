import 'dart:async';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_playback_state.dart';

abstract class AudioPlaybackService {
  Stream<AudioPlaybackState> get stateStream;

  Future<void> initialize(String filePath);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> dispose();
}
