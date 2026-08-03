import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide_page.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_playback_state.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/repositories/audio_guide_repository.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/usecases/download_audio_guide_usecase.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/usecases/get_audio_guides_usecase.dart';

// Fake Repository
class _FakeAudioGuideRepository implements AudioGuideRepository {
  int getCallCount = 0;
  int downloadCallCount = 0;
  String? requestedLang;
  int? requestedPage;
  AudioGuide? downloadedGuide;

  Future<AudioGuidePage> Function({required String lang, required int page})?
  onGet;
  Future<String> Function(AudioGuide guide)? onDownload;

  @override
  Future<AudioGuidePage> getAudioGuides({
    required String lang,
    required int page,
  }) async {
    getCallCount++;
    requestedLang = lang;
    requestedPage = page;
    if (onGet != null) return onGet!(lang: lang, page: page);
    return AudioGuidePage(
      total: 1,
      page: page,
      hasMore: false,
      items: [_guide],
    );
  }

  @override
  Future<String> downloadAudioGuide(AudioGuide guide) async {
    downloadCallCount++;
    downloadedGuide = guide;
    if (onDownload != null) return onDownload!(guide);
    return r'C:\audio\1.mp3';
  }

  @override
  Future<bool> isGuideDownloaded(AudioGuide guide) async => false;
}

// Test Fixture
const _guide = AudioGuide(
  id: 1,
  title: 'Guide 1',
  summary: 'Summary',
  url: 'https://example.com/1.mp3',
  fileExt: 'mp3',
  modified: '2026-05-01',
  isDownloaded: false,
);

// Tests
void main() {
  // AudioGuide entity
  group('AudioGuide entity', () {
    test('copyWith updates selected fields and keeps others', () {
      final updated = _guide.copyWith(
        isDownloaded: true,
        localFilePath: r'C:\audio\1.mp3',
      );
      expect(updated.id, _guide.id);
      expect(updated.title, _guide.title);
      expect(updated.url, _guide.url);
      expect(updated.isDownloaded, isTrue);
      expect(updated.localFilePath, r'C:\audio\1.mp3');
    });
    test('copyWith with no arguments returns same values', () {
      final copy = _guide.copyWith();
      expect(copy.id, _guide.id);
      expect(copy.title, _guide.title);
      expect(copy.isDownloaded, _guide.isDownloaded);
      expect(copy.localFilePath, _guide.localFilePath);
    });
    test('copyWith does not mutate original', () {
      final copy = _guide.copyWith(
        isDownloaded: true,
        localFilePath: '/audio/1.mp3',
      );
      expect(copy.isDownloaded, isTrue);
      expect(copy.localFilePath, '/audio/1.mp3');
      expect(_guide.isDownloaded, isFalse);
      expect(_guide.localFilePath, isNull);
    });
    test('nullable fields can be null', () {
      const guide = AudioGuide(
        id: 2,
        title: 'Guide 2',
        url: 'https://example.com/2.mp3',
        modified: '2026-01-01',
        isDownloaded: false,
      );
      expect(guide.summary, isNull);
      expect(guide.fileExt, isNull);
    });
  });
  // AudioPlaybackState
  group('AudioPlaybackState', () {
    test('default state is initial and not ready', () {
      const state = AudioPlaybackState();
      expect(state.status, AudioPlaybackStatus.initial);
      expect(state.isReady, isFalse);
      expect(state.isPlaying, isFalse);
      expect(state.hasError, isFalse);
    });
    test('computed getters reflect playback status', () {
      const playing = AudioPlaybackState(status: AudioPlaybackStatus.playing);
      const loading = AudioPlaybackState(status: AudioPlaybackStatus.loading);
      const error = AudioPlaybackState(
        status: AudioPlaybackStatus.error,
        errorMessage: 'failed',
      );
      const completed = AudioPlaybackState(
        status: AudioPlaybackStatus.stopped,
        position: Duration(seconds: 10),
        duration: Duration(seconds: 10),
      );
      expect(playing.isReady, isTrue);
      expect(playing.isPlaying, isTrue);
      expect(loading.isLoading, isTrue);
      expect(error.hasError, isTrue);
      expect(completed.isCompleted, isTrue);
    });
    test('isCompleted is false when duration is zero even if stopped', () {
      const state = AudioPlaybackState(
        status: AudioPlaybackStatus.stopped,
      );
      expect(state.isCompleted, isFalse);
    });
    test('isCompleted is false when playing even at end position', () {
      const state = AudioPlaybackState(
        status: AudioPlaybackStatus.playing,
        position: Duration(seconds: 60),
        duration: Duration(seconds: 60),
      );
      expect(state.isCompleted, isFalse);
    });
    test('isReady is true for playing, paused, stopped', () {
      expect(
        const AudioPlaybackState(status: AudioPlaybackStatus.paused).isReady,
        isTrue,
      );
      expect(
        const AudioPlaybackState(status: AudioPlaybackStatus.stopped).isReady,
        isTrue,
      );
    });
    test('isReady is false for initial, loading, error', () {
      expect(
        const AudioPlaybackState().isReady,
        isFalse,
      );
      expect(
        const AudioPlaybackState(status: AudioPlaybackStatus.error).isReady,
        isFalse,
      );
    });
    test('copyWith can clear error message', () {
      const state = AudioPlaybackState(
        status: AudioPlaybackStatus.error,
        errorMessage: 'failed',
      );
      final updated = state.copyWith(
        status: AudioPlaybackStatus.stopped,
        errorMessage: null,
      );
      expect(updated.status, AudioPlaybackStatus.stopped);
      expect(updated.errorMessage, isNull);
    });
    test('copyWith preserves errorMessage when clearError is false', () {
      const state = AudioPlaybackState(
        status: AudioPlaybackStatus.error,
        errorMessage: 'failed',
      );
      final updated = state.copyWith(status: AudioPlaybackStatus.stopped);
      expect(updated.errorMessage, 'failed');
    });
    test('copyWith updates position and duration independently', () {
      const state = AudioPlaybackState(
        status: AudioPlaybackStatus.playing,
        position: Duration(seconds: 10),
        duration: Duration(seconds: 120),
      );
      final updated = state.copyWith(position: const Duration(seconds: 50));
      expect(updated.position, const Duration(seconds: 50));
      expect(updated.duration, const Duration(seconds: 120));
    });
  });
  // Use Cases
  group('UseCases', () {
    group('GetAudioGuidesUseCase', () {
      test('delegates to repository with correct lang and page', () async {
        final repo = _FakeAudioGuideRepository();
        final useCase = GetAudioGuidesUseCase(repo);
        final result = await useCase(lang: 'zh-tw', page: 2);
        expect(repo.getCallCount, 1);
        expect(repo.requestedLang, 'zh-tw');
        expect(repo.requestedPage, 2);
        expect(result.items.single.id, 1);
      });
      test('propagates repository exception', () async {
        final repo = _FakeAudioGuideRepository()
          ..onGet = ({required lang, required page}) async =>
              throw Exception('network error');
        final useCase = GetAudioGuidesUseCase(repo);
        expect(() => useCase(lang: 'zh-tw', page: 1), throwsException);
      });
      test('each call increments repository call count', () async {
        final repo = _FakeAudioGuideRepository();
        final useCase = GetAudioGuidesUseCase(repo);
        await useCase(lang: 'zh-tw', page: 1);
        await useCase(lang: 'zh-tw', page: 2);
        expect(repo.getCallCount, 2);
      });
    });
    group('DownloadAudioGuideUseCase', () {
      test('delegates to repository and returns path', () async {
        final repo = _FakeAudioGuideRepository();
        final useCase = DownloadAudioGuideUseCase(repo);
        final path = await useCase(_guide);
        expect(path, r'C:\audio\1.mp3');
        expect(repo.downloadCallCount, 1);
        expect(repo.downloadedGuide, _guide);
      });
      test('propagates repository exception', () async {
        final repo = _FakeAudioGuideRepository()
          ..onDownload = (_) async => throw Exception('disk full');
        final useCase = DownloadAudioGuideUseCase(repo);
        expect(() => useCase(_guide), throwsException);
      });
    });
  });
}
