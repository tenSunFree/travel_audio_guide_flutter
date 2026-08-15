import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';

void main() {
  group('AudioGuide entity', () {
    test('isDownloaded is false by default', () {
      const guide = AudioGuide(
        id: 1,
        title: 'Test',
        summary: 'Summary',
        url: 'https://example.com/1.mp3',
        fileExt: 'mp3',
        modified: '2026-01-01',
        isDownloaded: false,
      );
      expect(guide.isDownloaded, isFalse);
      expect(guide.localFilePath, isNull);
    });
    test('isDownloaded is true when localFilePath is set', () {
      const guide = AudioGuide(
        id: 2,
        title: 'Test',
        summary: 'Summary',
        url: 'https://example.com/2.mp3',
        fileExt: 'mp3',
        modified: '2026-01-01',
        isDownloaded: true,
        localFilePath: '/audio/2.mp3',
      );
      expect(guide.isDownloaded, isTrue);
      expect(guide.localFilePath, '/audio/2.mp3');
    });
  });
}
