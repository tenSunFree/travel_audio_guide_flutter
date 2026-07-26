import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';

Attraction buildAttraction({
  List<AttractionImage> images = const [],
  List<AttractionCategory> categories = const [],
  List<AttractionTag> targets = const [],
  List<AttractionTag> friendlies = const [],
  double? nlat,
  double? elong,
}) {
  return Attraction(
    id: 1,
    name: '測試景點',
    introduction: '',
    openTime: '',
    distric: '',
    address: '',
    tel: '',
    officialSite: '',
    facebook: '',
    ticket: '',
    remind: '',
    modified: '',
    url: '',
    categories: categories,
    targets: targets,
    friendlies: friendlies,
    images: images,
    nlat: nlat,
    elong: elong,
  );
}

void main() {
  group('Attraction getters', () {
    test('firstImageUrl / hasImage', () {
      final withImage = buildAttraction(
        images: const [
          AttractionImage(
            src: 'https://x.com/a.jpg',
            subject: '封面',
            ext: '.jpg',
          ),
        ],
      );
      final withoutImage = buildAttraction();
      expect(withImage.firstImageUrl, 'https://x.com/a.jpg');
      expect(withImage.hasImage, isTrue);
      expect(withoutImage.firstImageUrl, isEmpty);
      expect(withoutImage.hasImage, isFalse);
    });

    test('hasValidCoordinate 必須符合有效範圍', () {
      expect(
        buildAttraction(nlat: 25.03, elong: 121.56).hasValidCoordinate,
        isTrue,
      );
      expect(buildAttraction().hasValidCoordinate, isFalse);
      expect(buildAttraction(nlat: 0, elong: 0).hasValidCoordinate, isFalse);
      expect(buildAttraction(nlat: 25, elong: 99).hasValidCoordinate, isFalse);
    });

    test('categoryText 正確組合分類', () {
      final attraction = buildAttraction(
        categories: const [
          AttractionCategory(id: 1, name: '歷史'),
          AttractionCategory(id: 2, name: '文化'),
        ],
      );
      expect(attraction.categoryText, '歷史・文化');
      expect(buildAttraction().categoryText, isEmpty);
    });

    test('hasFriendly 與 hasTarget 依 id 判斷', () {
      final attraction = buildAttraction(
        friendlies: const [AttractionTag(id: 10, name: '親子')],
        targets: const [AttractionTag(id: 20, name: '銀髮')],
      );
      expect(attraction.hasFriendly(10), isTrue);
      expect(attraction.hasFriendly(99), isFalse);
      expect(attraction.hasTarget(20), isTrue);
      expect(attraction.hasTarget(99), isFalse);
    });
  });
}
