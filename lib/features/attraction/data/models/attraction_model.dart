import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'attraction_model.freezed.dart';
part 'attraction_model.g.dart';

double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  final d = value is num ? value.toDouble() : double.tryParse('$value');
  if (d == null || d <= 1.0) return null;
  return d;
}

@freezed
abstract class AttractionTagModel with _$AttractionTagModel {
  const factory AttractionTagModel({
    @Default(0) int id,
    @Default('') String name,
  }) = _AttractionTagModel;
  const AttractionTagModel._();

  factory AttractionTagModel.fromJson(Map<String, dynamic> json) =>
      _$AttractionTagModelFromJson(json);

  AttractionTag toEntity() => AttractionTag(id: id, name: name);
}

@freezed
abstract class AttractionCategoryModel with _$AttractionCategoryModel {
  const factory AttractionCategoryModel({
    @Default(0) int id,
    @Default('') String name,
  }) = _AttractionCategoryModel;
  const AttractionCategoryModel._();

  factory AttractionCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$AttractionCategoryModelFromJson(json);

  AttractionCategory toEntity() => AttractionCategory(id: id, name: name);
}

@freezed
abstract class AttractionImageModel with _$AttractionImageModel {
  const factory AttractionImageModel({
    @Default('') String src,
    @Default('') String subject,
    @Default('') String ext,
  }) = _AttractionImageModel;
  const AttractionImageModel._();

  factory AttractionImageModel.fromJson(Map<String, dynamic> json) =>
      _$AttractionImageModelFromJson(json);

  AttractionImage toEntity() =>
      AttractionImage(src: src, subject: subject, ext: ext);
}

@freezed
abstract class AttractionModel with _$AttractionModel {
  const factory AttractionModel({
    @Default(0) int id,
    @Default('') String name,
    @Default('') String introduction,
    @JsonKey(name: 'open_time') @Default('') String openTime,
    @Default('') String distric,
    @Default('') String address,
    @Default('') String tel,
    double? nlat,
    double? elong,
    @JsonKey(name: 'official_site') @Default('') String officialSite,
    @Default('') String facebook,
    @Default('') String ticket,
    @Default('') String remind,
    @Default('') String modified,
    @Default('') String url,
    @JsonKey(name: 'category')
    @Default([])
    List<AttractionCategoryModel> categories,
    @JsonKey(name: 'target') @Default([]) List<AttractionTagModel> targets,
    @JsonKey(name: 'friendly') @Default([]) List<AttractionTagModel> friendlies,
    @Default([]) List<AttractionImageModel> images,
  }) = _AttractionModel;
  const AttractionModel._();

  factory AttractionModel.fromJson(Map<String, dynamic> json) =>
      _attractionModelFromJson(json);

  Attraction toEntity() {
    return Attraction(
      id: id,
      name: name,
      introduction: introduction,
      openTime: openTime,
      distric: distric,
      address: address,
      tel: tel,
      nlat: nlat,
      elong: elong,
      officialSite: officialSite,
      facebook: facebook,
      ticket: ticket,
      remind: remind,
      modified: modified,
      url: url,
      categories: categories.map((e) => e.toEntity()).toList(),
      targets: targets.map((e) => e.toEntity()).toList(),
      friendlies: friendlies.map((e) => e.toEntity()).toList(),
      images: images.map((e) => e.toEntity()).toList(),
    );
  }
}

AttractionModel _attractionModelFromJson(Map<String, dynamic> json) {
  final patched = Map<String, dynamic>.from(json)
    ..['nlat'] = _toDoubleOrNull(json['nlat'])
    ..['elong'] = _toDoubleOrNull(json['elong']);
  return _$AttractionModelFromJson(patched);
}
