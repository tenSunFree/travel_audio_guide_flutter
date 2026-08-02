import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_playback_state.freezed.dart';

enum AudioPlaybackStatus { initial, loading, playing, paused, stopped, error }

@freezed
abstract class AudioPlaybackState with _$AudioPlaybackState {
  const factory AudioPlaybackState({
    @Default(AudioPlaybackStatus.initial) AudioPlaybackStatus status,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
    String? errorMessage,
  }) = _AudioPlaybackState;
  const AudioPlaybackState._();

  bool get isReady =>
      status == AudioPlaybackStatus.playing ||
      status == AudioPlaybackStatus.paused ||
      status == AudioPlaybackStatus.stopped;

  bool get isPlaying => status == AudioPlaybackStatus.playing;

  bool get isLoading => status == AudioPlaybackStatus.loading;

  bool get hasError => status == AudioPlaybackStatus.error;

  bool get isCompleted =>
      status == AudioPlaybackStatus.stopped &&
      duration > Duration.zero &&
      position >= duration;
}
