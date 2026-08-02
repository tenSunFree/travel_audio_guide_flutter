import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/models/audio_guide_model.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/models/audio_guide_page_model.dart';

void main() {
  group('AudioGuideModel', () {
    // fromJson
    group('fromJson', () {
      test('maps all API fields correctly', () {
        final model = AudioGuideModel.fromJson({
          'id': 10,
          'title': '台北 101 語音導覽',
          'summary': '景點介紹',
          'url': 'https://example.com/101.mp3',
          'file_ext': 'mp3',
          'modified': '2026-05-01 10:00:00',
        });
        expect(model.id, 10);
        expect(model.title, '台北 101 語音導覽');
        expect(model.summary, '景點介紹');
        expect(model.url, 'https://example.com/101.mp3');
        expect(model.fileExt, 'mp3');
        expect(model.modified, '2026-05-01 10:00:00');
      });
      test('uses safe default values when nullable fields are missing', () {
        final model = AudioGuideModel.fromJson({'id': 1});
        expect(model.id, 1);
        expect(model.title, '');
        expect(model.summary, isNull);
        expect(model.url, '');
        expect(model.fileExt, isNull);
        expect(model.modified, '');
      });
      test('summary null is preserved', () {
        final model = AudioGuideModel.fromJson({
          'id': 2,
          'title': 'Guide',
          'summary': null,
          'url': 'https://example.com/2.mp3',
          'modified': '2026-01-01',
        });
        expect(model.summary, isNull);
      });
      test('file_ext null is preserved', () {
        final model = AudioGuideModel.fromJson({
          'id': 3,
          'title': 'Guide',
          'url': 'https://example.com/3.mp3',
          'file_ext': null,
          'modified': '2026-01-01',
        });
        expect(model.fileExt, isNull);
      });
    });
    // toEntity
    group('toEntity', () {
      test('keeps download status and local path when downloaded', () {
        final model = AudioGuideModel.fromJson({
          'id': 2,
          'title': 'Guide 2',
          'url': 'https://example.com/2.mp3',
          'modified': '2026-05-02',
        });
        final entity = model.toEntity(
          isDownloaded: true,
          localFilePath: r'C:\audio\2.mp3',
        );
        expect(entity.id, 2);
        expect(entity.title, 'Guide 2');
        expect(entity.isDownloaded, isTrue);
        expect(entity.localFilePath, r'C:\audio\2.mp3');
      });
      test('isDownloaded false and localFilePath null when not downloaded', () {
        final model = AudioGuideModel.fromJson({
          'id': 5,
          'title': 'Guide 5',
          'url': 'https://example.com/5.mp3',
          'modified': '2026-05-01',
        });
        final entity = model.toEntity(isDownloaded: false, localFilePath: null);
        expect(entity.isDownloaded, isFalse);
        expect(entity.localFilePath, isNull);
      });
      test('all fields are correctly transferred to entity', () {
        final model = AudioGuideModel.fromJson({
          'id': 7,
          'title': '故宮導覽',
          'summary': '收藏品簡介',
          'url': 'https://cdn.example.com/7.mp3',
          'file_ext': 'mp3',
          'modified': '2025-12-01',
        });
        final entity = model.toEntity(isDownloaded: false, localFilePath: null);
        expect(entity.id, 7);
        expect(entity.title, '故宮導覽');
        expect(entity.summary, '收藏品簡介');
        expect(entity.url, 'https://cdn.example.com/7.mp3');
        expect(entity.fileExt, 'mp3');
        expect(entity.modified, '2025-12-01');
      });
    });
  });
  // AudioGuidePageModel
  group('AudioGuidePageModel', () {
    test('fromJson maps total, page and data list', () {
      final page = AudioGuidePageModel.fromJson({
        'total': 2,
        'data': [
          {'id': 1, 'title': 'A'},
          {'id': 2, 'title': 'B'},
        ],
      }, 3);
      expect(page.total, 2);
      expect(page.page, 3);
      expect(page.data.map((e) => e.id), <int>[1, 2]);
    });
    test('fromJson returns empty list when data is missing', () {
      final page = AudioGuidePageModel.fromJson({}, 1);
      expect(page.total, 0);
      expect(page.page, 1);
      expect(page.data, isEmpty);
    });
    test('page number comes from the argument, not JSON', () {
      final page = AudioGuidePageModel.fromJson({
        'total': 10,
        'data': <Map<String, dynamic>>[],
      }, 5);
      expect(page.page, 5);
    });
    test('data items are correctly deserialized as AudioGuideModel', () {
      final page = AudioGuidePageModel.fromJson({
        'total': 1,
        'data': [
          {
            'id': 99,
            'title': '特定導覽',
            'summary': '說明',
            'url': 'https://cdn.example.com/99.mp3',
            'file_ext': 'mp3',
            'modified': '2025-11-20',
          },
        ],
      }, 1);
      final item = page.data.first;
      expect(item.id, 99);
      expect(item.title, '特定導覽');
      expect(item.modified, '2025-11-20');
    });
  });
}
