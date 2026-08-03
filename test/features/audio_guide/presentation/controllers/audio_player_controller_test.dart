import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_playback_state.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/controllers/audio_player_controller.dart';
import '../../../../test_helpers/audio_playback_service_fake.dart';

// Helper
/// Flush the microtask queue so async _init() completes
Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

// Tests
void main() {
  group('AudioPlayerController', () {
    // initialization
    group('initialization', () {
      test('initializes service with provided path', () async {
        final service = FakeAudioPlaybackService();
        final controller = AudioPlayerController(service, '/audio/1.mp3');
        addTearDown(controller.dispose);
        addTearDown(service.dispose);
        await _flush();
        expect(service.initializeCallCount, 1);
        expect(service.initializedPath, '/audio/1.mp3');
      });
      test('starts with initial AudioPlaybackState', () {
        final service = FakeAudioPlaybackService();
        final controller = AudioPlayerController(service, '/audio/1.mp3');
        addTearDown(controller.dispose);
        addTearDown(service.dispose);
        expect(controller.state.status, AudioPlaybackStatus.initial);
      });
      test('updates state when service emits playback state', () async {
        final service = FakeAudioPlaybackService();
        final controller = AudioPlayerController(service, '/audio/1.mp3');
        addTearDown(controller.dispose);
        addTearDown(service.dispose);
        await _flush();
        service.emit(
          const AudioPlaybackState(
            status: AudioPlaybackStatus.playing,
            position: Duration(seconds: 3),
            duration: Duration(seconds: 10),
          ),
        );
        await _flush();
        expect(controller.state.status, AudioPlaybackStatus.playing);
        expect(controller.state.position, const Duration(seconds: 3));
        expect(controller.state.duration, const Duration(seconds: 10));
      });
      test('reflects multiple state updates in order', () async {
        final service = FakeAudioPlaybackService();
        final controller = AudioPlayerController(service, '/audio/1.mp3');
        addTearDown(controller.dispose);
        addTearDown(service.dispose);
        await _flush();
        service.emit(
          const AudioPlaybackState(status: AudioPlaybackStatus.loading),
        );
        await _flush();
        expect(controller.state.status, AudioPlaybackStatus.loading);
        service.emit(
          const AudioPlaybackState(status: AudioPlaybackStatus.stopped),
        );
        await _flush();
        expect(controller.state.status, AudioPlaybackStatus.stopped);
      });
    });
    // togglePlayPause
    group('togglePlayPause', () {
      test('does nothing when state is not ready (initial)', () async {
        final service = FakeAudioPlaybackService();
        final controller = AudioPlayerController(service, '/audio/1.mp3');
        addTearDown(controller.dispose);
        addTearDown(service.dispose);
        await _flush();
        // Initial state = initial, not ready
        expect(controller.state.isReady, isFalse);
        await controller.togglePlayPause();
        expect(service.playCallCount, 0);
        expect(service.pauseCallCount, 0);
      });
      test('pauses when currently playing', () async {
        final service = FakeAudioPlaybackService();
        final controller = AudioPlayerController(service, '/audio/1.mp3');
        addTearDown(controller.dispose);
        addTearDown(service.dispose);
        await _flush();
        service.emit(
          const AudioPlaybackState(status: AudioPlaybackStatus.playing),
        );
        await _flush();
        await controller.togglePlayPause();
        expect(service.pauseCallCount, 1);
        expect(service.playCallCount, 0);
      });
      test('plays when ready but not playing (paused)', () async {
        final service = FakeAudioPlaybackService();
        final controller = AudioPlayerController(service, '/audio/1.mp3');
        addTearDown(controller.dispose);
        addTearDown(service.dispose);
        await _flush();
        service.emit(
          const AudioPlaybackState(status: AudioPlaybackStatus.paused),
        );
        await _flush();
        await controller.togglePlayPause();
        expect(service.playCallCount, 1);
        expect(service.pauseCallCount, 0);
      });
      test(
        'plays when ready but not playing (stopped, not completed)',
        () async {
          final service = FakeAudioPlaybackService();
          final controller = AudioPlayerController(service, '/audio/1.mp3');
          addTearDown(controller.dispose);
          addTearDown(service.dispose);
          await _flush();
          // stopped + duration=0 → isReady=true, isCompleted=false
          service.emit(
            const AudioPlaybackState(
              status: AudioPlaybackStatus.stopped,
            ),
          );
          await _flush();
          await controller.togglePlayPause();
          // Don't seek, just play
          expect(service.seekCallCount, 0);
          expect(service.playCallCount, 1);
        },
      );
      test('seeks to zero before replaying completed audio', () async {
        final service = FakeAudioPlaybackService();
        final controller = AudioPlayerController(service, '/audio/1.mp3');
        addTearDown(controller.dispose);
        addTearDown(service.dispose);
        await _flush();
        // Playback complete status: stopped + position == duration > 0
        service.emit(
          const AudioPlaybackState(
            status: AudioPlaybackStatus.stopped,
            position: Duration(seconds: 10),
            duration: Duration(seconds: 10),
          ),
        );
        await _flush();
        expect(controller.state.isCompleted, isTrue);
        await controller.togglePlayPause();
        expect(service.seekCallCount, 1);
        expect(service.seekPositions.single, Duration.zero);
        expect(service.playCallCount, 1);
      });
    });
    // seek
    group('seek', () {
      test('delegates to service only when state is ready', () async {
        final service = FakeAudioPlaybackService();
        final controller = AudioPlayerController(service, '/audio/1.mp3');
        addTearDown(controller.dispose);
        addTearDown(service.dispose);
        await _flush();
        // Initial = not ready → seek (does not call)
        await controller.seek(const Duration(seconds: 5));
        expect(service.seekCallCount, 0);
        // Switch to paused (ready) → seek call
        service.emit(
          const AudioPlaybackState(status: AudioPlaybackStatus.paused),
        );
        await _flush();
        await controller.seek(const Duration(seconds: 5));
        expect(service.seekCallCount, 1);
        expect(service.seekPositions.single, const Duration(seconds: 5));
      });
      test('passes correct position to service', () async {
        final service = FakeAudioPlaybackService();
        final controller = AudioPlayerController(service, '/audio/1.mp3');
        addTearDown(controller.dispose);
        addTearDown(service.dispose);
        await _flush();
        service.emit(
          const AudioPlaybackState(status: AudioPlaybackStatus.playing),
        );
        await _flush();
        await controller.seek(const Duration(seconds: 30));
        expect(service.seekPositions.single, const Duration(seconds: 30));
      });
      test('accepts Duration.zero', () async {
        final service = FakeAudioPlaybackService();
        final controller = AudioPlayerController(service, '/audio/1.mp3');
        addTearDown(controller.dispose);
        addTearDown(service.dispose);
        await _flush();
        service.emit(
          const AudioPlaybackState(status: AudioPlaybackStatus.stopped),
        );
        await _flush();
        await controller.seek(Duration.zero);
        expect(service.seekPositions.single, Duration.zero);
      });
    });
    // dispose
    group('dispose', () {
      test('cancels stream subscription so service emit does not throw', () async {
        final service = FakeAudioPlaybackService();
        final controller = AudioPlayerController(service, '/audio/1.mp3');
        await _flush();
        service.emit(
          const AudioPlaybackState(status: AudioPlaybackStatus.stopped),
        );
        await _flush();
        // Confirm normal status before disposing
        expect(controller.state.status, AudioPlaybackStatus.stopped);
        controller.dispose();
        // After dispose, the service should continue emitting without throwing an exception.
        // (Subscription has been cancelled, stream events will be ignored)
        expect(
          () => service.emit(
            const AudioPlaybackState(status: AudioPlaybackStatus.playing),
          ),
          returnsNormally,
        );
        // Note: Since `.state` cannot be read after `StateNotifier dispose`, no state assertion is performed.
        await service.dispose();
      });
    });
  });
}
