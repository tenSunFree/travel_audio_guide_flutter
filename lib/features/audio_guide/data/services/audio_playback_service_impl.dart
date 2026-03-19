import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../../domain/services/audio_playback_service.dart';

class AudioPlaybackServiceImpl implements AudioPlaybackService {
  AudioPlaybackServiceImpl() {
    _stateController.add(_state);
    _initStreams();
  }

  final AudioPlayer _player = AudioPlayer();
  final StreamController<AudioPlaybackState> _stateController =
      StreamController<AudioPlaybackState>.broadcast();

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  AudioPlaybackState _state = const AudioPlaybackState();

  @override
  Stream<AudioPlaybackState> get stateStream => _stateController.stream;

  void _updateState(AudioPlaybackState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  void _initStreams() {
    _subscriptions.add(
      _player.onDurationChanged.listen((duration) {
        _updateState(_state.copyWith(duration: duration));
      }),
    );

    _subscriptions.add(
      _player.onPositionChanged.listen((position) {
        _updateState(_state.copyWith(position: position));
      }),
    );

    _subscriptions.add(
      _player.onPlayerStateChanged.listen((playerState) {
        _updateState(_state.copyWith(status: _mapStatus(playerState)));
      }),
    );

    _subscriptions.add(
      _player.onPlayerComplete.listen((_) {
        _updateState(
          _state.copyWith(
            status: AudioPlaybackStatus.stopped,
            position: _state.duration,
          ),
        );
      }),
    );
  }

  AudioPlaybackStatus _mapStatus(PlayerState playerState) {
    switch (playerState) {
      case PlayerState.playing:
        return AudioPlaybackStatus.playing;
      case PlayerState.paused:
        return AudioPlaybackStatus.paused;
      case PlayerState.completed:
      case PlayerState.stopped:
        return AudioPlaybackStatus.stopped;
      case PlayerState.disposed:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  Future<void> initialize(String filePath) async {
    _updateState(
      _state.copyWith(status: AudioPlaybackStatus.loading, clearError: true),
    );

    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setSource(DeviceFileSource(filePath));

      _updateState(
        _state.copyWith(status: AudioPlaybackStatus.stopped, clearError: true),
      );
    } catch (e) {
      _updateState(
        _state.copyWith(
          status: AudioPlaybackStatus.error,
          errorMessage: '播放器初始化失敗：$e',
        ),
      );
    }
  }

  @override
  Future<void> play() async {
    try {
      await _player.resume();

      _updateState(_state.copyWith(clearError: true));
    } catch (e) {
      _updateState(
        _state.copyWith(
          status: AudioPlaybackStatus.error,
          errorMessage: '播放失敗：$e',
        ),
      );
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();

      _updateState(_state.copyWith(clearError: true));
    } catch (e) {
      _updateState(
        _state.copyWith(
          status: AudioPlaybackStatus.error,
          errorMessage: '暫停失敗：$e',
        ),
      );
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);

      _updateState(_state.copyWith(clearError: true));
    } catch (e) {
      _updateState(
        _state.copyWith(
          status: AudioPlaybackStatus.error,
          errorMessage: '跳轉失敗：$e',
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    await _player.dispose();
    await _stateController.close();
  }
}
