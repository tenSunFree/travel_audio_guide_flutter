import 'package:freezed_annotation/freezed_annotation.dart';

part 'attraction.freezed.dart';

@freezed
abstract class Attraction with _$Attraction {
  const factory Attraction({
    required int id,
    required String name,
    required String introduction,
    required String openTime,
    required String distric,
    required String address,
    required String tel,
    required String officialSite,
    required String facebook,
    required String ticket,
    required String remind,
    required String modified,
    required String url,
    required List<AttractionCategory> categories,
    required List<AttractionTag> targets,
    required List<AttractionTag> friendlies,
    required List<AttractionImage> images,
    double? nlat,
    double? elong,
  }) = _Attraction;
  const Attraction._();

  String get firstImageUrl => images.isNotEmpty ? images.first.src : '';

  bool get hasImage => firstImageUrl.isNotEmpty;

  bool get hasValidCoordinate =>
      nlat != null && elong != null && nlat! > 1.0 && elong! > 100.0;

  String get categoryText {
    if (categories.isEmpty) return '';
    return categories.map((e) => e.name).join('・');
  }

  bool hasFriendly(int id) => friendlies.any((f) => f.id == id);

  bool hasTarget(int id) => targets.any((t) => t.id == id);
}

@freezed
abstract class AttractionTag with _$AttractionTag {
  const factory AttractionTag({required int id, required String name}) =
      _AttractionTag;
}

@freezed
abstract class AttractionCategory with _$AttractionCategory {
  const factory AttractionCategory({required int id, required String name}) =
      _AttractionCategory;
}

@freezed
abstract class AttractionImage with _$AttractionImage {
  const factory AttractionImage({
    required String src,
    required String subject,
    required String ext,
  }) = _AttractionImage;
}
