import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/models/activity_model.dart';

void main() {
  group('ActivityModel', () {
    group('fromJson — links normalization', () {
      test('normal JSON list of link maps is parsed correctly', () {
        final model = ActivityModel.fromJson({
          'id': 1,
          'title': '台北燈節',
          'links': [
            {'src': 'https://example.com', 'subject': '官網'},
          ],
        });
        expect(model.links, hasLength(1));
        expect(model.links.single.src, 'https://example.com');
        expect(model.links.single.subject, '官網');
      });

      test('non-map, non-model entries in links are skipped', () {
        final model = ActivityModel.fromJson({
          'id': 1,
          'title': '台北燈節',
          'links': [
            {'src': 'https://example.com', 'subject': '官網'},
            null,
            123,
            'not-a-link',
          ],
        });
        expect(model.links, hasLength(1));
      });

      test(
        'links that are already ActivityLinkModel instances are '
        're-serialized via toJson (defensive re-parse path)',
        () {
          // Simulates the case where the raw JSON has already been parsed
          // once (e.g. cached and passed back through fromJson again).
          const alreadyParsed = ActivityLinkModel(
            src: 'https://example.com/cached',
            subject: '快取連結',
          );
          final model = ActivityModel.fromJson({
            'id': 1,
            'title': '台北燈節',
            'links': [alreadyParsed],
          });
          expect(model.links, hasLength(1));
          expect(model.links.single.src, 'https://example.com/cached');
          expect(model.links.single.subject, '快取連結');
        },
      );

      test('missing links field results in an empty list', () {
        final model = ActivityModel.fromJson({'id': 1, 'title': '台北燈節'});
        expect(model.links, isEmpty);
      });

      test('non-list links field results in an empty list', () {
        final model = ActivityModel.fromJson({
          'id': 1,
          'title': '台北燈節',
          'links': 'not-a-list',
        });
        expect(model.links, isEmpty);
      });
    });

    group('toEntity', () {
      test('maps every field including nested links', () {
        final model = ActivityModel.fromJson({
          'id': 9,
          'title': '台北燈節',
          'description': '<p>介紹</p>',
          'begin': '2026-08-01',
          'end': '2026-08-10',
          'posted': '2026-07-01',
          'modified': '2026-07-25',
          'url': 'https://example.com',
          'address': '台北市中正區',
          'distric': '中正區',
          'nlat': '25.03',
          'elong': '121.56',
          'organizer': '臺北市政府',
          'co_rganizer': '協辦單位',
          'contact': '聯絡人',
          'tel': '02-1234-5678',
          'ticket': '免費',
          'traffic': '捷運',
          'parking': '路邊停車',
          'links': [
            {'src': 'https://example.com', 'subject': '官網'},
          ],
        });
        final entity = model.toEntity();
        expect(entity.id, 9);
        expect(entity.title, '台北燈節');
        expect(entity.coRganizer, '協辦單位');
        expect(entity.links, hasLength(1));
        expect(entity.links.single.subject, '官網');
      });
    });
  });
}
