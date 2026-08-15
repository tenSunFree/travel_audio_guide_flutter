import 'package:flutter_travel_audio_guide/features/audio_guide/data/models/audio_guide_model.dart';

class AudioGuidePageModel {
  const AudioGuidePageModel({
    required this.total,
    required this.page,
    required this.data,
  });

  factory AudioGuidePageModel.fromJson(Map<String, dynamic> json, int page) {
    final rawList = (json['data'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return AudioGuidePageModel(
      total: json['total'] as int? ?? 0,
      page: page,
      data: rawList.map(AudioGuideModel.fromJson).toList(),
    );
  }

  final int total;
  final int page;
  final List<AudioGuideModel> data;
}
