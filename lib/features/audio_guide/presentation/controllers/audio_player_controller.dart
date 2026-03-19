import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/audio_playback_service_impl.dart';
import '../../domain/services/audio_playback_service.dart';

final audioPlaybackServiceProvider = Provider.autoDispose
    .family<AudioPlaybackService, String>((ref, path) {
      final service = AudioPlaybackServiceImpl();
      ref.onDispose(() {
        service.dispose();
      });
      return service;
    });

final audioPlayerControllerProvider = StateNotifierProvider.autoDispose
    .family<AudioPlayerController, AudioPlaybackState, String>((ref, path) {
      final service = ref.watch(audioPlaybackServiceProvider(path));
      return AudioPlayerController(service, path);
    });

class AudioPlayerController extends StateNotifier<AudioPlaybackState> {
  AudioPlayerController(this._service, this._path)
    : super(const AudioPlaybackState()) {
    _init();
  }

  final AudioPlaybackService _service;
  final String _path;

  StreamSubscription<AudioPlaybackState>? _subscription;

  Future<void> _init() async {
    _subscription = _service.stateStream.listen((playbackState) {
      state = playbackState;
    });
    await _service.initialize(_path);
  }

  Future<void> togglePlayPause() async {
    if (!state.isReady) return;
    if (state.isPlaying) {
      await _service.pause();
      return;
    }
    if (state.status == AudioPlaybackStatus.stopped &&
        state.duration > Duration.zero &&
        state.position >= state.duration) {
      await _service.seek(Duration.zero);
    }
    await _service.play();
  }

  Future<void> seek(Duration position) async {
    if (!state.isReady) return;
    await _service.seek(position);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
