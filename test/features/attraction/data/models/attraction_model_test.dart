import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/models/attraction_model.dart';

void main() {
  group('AttractionModel', () {
    group('fromJson — coordinate normalization', () {
      test('numeric nlat/elong are kept as-is', () {
        final model = AttractionModel.fromJson({
          'id': 1,
          'name': '故宮博物院',
          'nlat': 25.1024,
          'elong': 121.5486,
        });
        expect(model.nlat, 25.1024);
        expect(model.elong, 121.5486);
      });

      test('numeric strings are parsed to double', () {
        final model = AttractionModel.fromJson({
          'id': 1,
          'name': '故宮博物院',
          'nlat': '25.1024',
          'elong': '121.5486',
        });
        expect(model.nlat, 25.1024);
        expect(model.elong, 121.5486);
      });

      test('placeholder values (<= 1.0) are normalized to null', () {
        // The Taipei Travel Open API sometimes returns "0" or "1" for
        // attractions with no real coordinates instead of omitting the
        // field entirely.
        final model = AttractionModel.fromJson({
          'id': 1,
          'name': '無座標景點',
          'nlat': 0,
          'elong': 1,
        });
        expect(model.nlat, isNull);
        expect(model.elong, isNull);
      });

      test('missing nlat/elong stay null', () {
        final model = AttractionModel.fromJson({'id': 1, 'name': '無座標景點'});
        expect(model.nlat, isNull);
        expect(model.elong, isNull);
      });

      test('non-numeric, non-parsable strings become null', () {
        final model = AttractionModel.fromJson({
          'id': 1,
          'name': '壞資料',
          'nlat': 'not-a-number',
        });
        expect(model.nlat, isNull);
      });
    });

    group('toEntity', () {
      test('maps categories, targets, friendlies, and images to entities', () {
        final model = AttractionModel.fromJson({
          'id': 5,
          'name': '大稻埕',
          'nlat': 25.06,
          'elong': 121.51,
          'category': [
            {'id': 1, 'name': '古蹟'},
          ],
          'target': [
            {'id': 60, 'name': '親子'},
          ],
          'friendly': [
            {'id': 392, 'name': '無障礙'},
          ],
          'images': [
            {'src': 'https://example.com/a.png', 'subject': '', 'ext': 'png'},
          ],
        });
        final entity = model.toEntity();
        expect(entity.id, 5);
        expect(entity.name, '大稻埕');
        expect(entity.nlat, 25.06);
        expect(entity.elong, 121.51);
        expect(entity.categories, hasLength(1));
        expect(entity.categories.single.name, '古蹟');
        expect(entity.targets, hasLength(1));
        expect(entity.targets.single.name, '親子');
        expect(entity.friendlies, hasLength(1));
        expect(entity.friendlies.single.name, '無障礙');
        expect(entity.images, hasLength(1));
        expect(entity.images.single.src, 'https://example.com/a.png');
      });

      test('empty lists round-trip to empty entity lists', () {
        final model = AttractionModel.fromJson({'id': 1, 'name': '空景點'});
        final entity = model.toEntity();
        expect(entity.categories, isEmpty);
        expect(entity.targets, isEmpty);
        expect(entity.friendlies, isEmpty);
        expect(entity.images, isEmpty);
      });
    });
  });
}
