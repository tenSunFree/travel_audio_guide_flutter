import 'dart:async';

enum AudioPlaybackStatus { initial, loading, playing, paused, stopped, error }

class AudioPlaybackState {
  const AudioPlaybackState({
    this.status = AudioPlaybackStatus.initial,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  final AudioPlaybackStatus status;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  bool get isReady =>
      status == AudioPlaybackStatus.playing ||
      status == AudioPlaybackStatus.paused ||
      status == AudioPlaybackStatus.stopped;

  bool get isPlaying => status == AudioPlaybackStatus.playing;

  AudioPlaybackState copyWith({
    AudioPlaybackStatus? status,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AudioPlaybackState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

abstract class AudioPlaybackService {
  Stream<AudioPlaybackState> get stateStream;

  Future<void> initialize(String filePath);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> dispose();
}
