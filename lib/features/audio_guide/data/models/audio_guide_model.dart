import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_guide_model.freezed.dart';
part 'audio_guide_model.g.dart';

@freezed
abstract class AudioGuideModel with _$AudioGuideModel {
  const factory AudioGuideModel({
    required int id,
    @Default('') String title,
    String? summary,
    @Default('') String url,
    @JsonKey(name: 'file_ext') String? fileExt,
    @Default('') String modified,
  }) = _AudioGuideModel;
  const AudioGuideModel._();

  factory AudioGuideModel.fromJson(Map<String, dynamic> json) =>
      _$AudioGuideModelFromJson(json);

  AudioGuide toEntity({
    required bool isDownloaded,
    required String? localFilePath,
  }) {
    return AudioGuide(
      id: id,
      title: title,
      summary: summary,
      url: url,
      fileExt: fileExt,
      modified: modified,
      isDownloaded: isDownloaded,
      localFilePath: localFilePath,
    );
  }
}
