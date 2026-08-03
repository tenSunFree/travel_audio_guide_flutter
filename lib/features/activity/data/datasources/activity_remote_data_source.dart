import 'package:dio/dio.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/models/activity_page_model.dart';

class ActivityRemoteDataSource {
  const ActivityRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ActivityPageModel> getActivities({
    required String lang,
    required int page,
    String? begin,
    String? end,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        if (begin != null && begin.isNotEmpty) 'begin': begin,
        if (end != null && end.isNotEmpty) 'end': end,
      };
      final response = await _dio.get<Map<String, dynamic>>(
        '/$lang/Events/Activity',
        queryParameters: query,
      );
      if (response.statusCode == 200 && response.data != null) {
        return ActivityPageModel.fromJson(response.data!, page);
      }
      if (response.statusCode == 204) {
        return ActivityPageModel(total: 0, page: page, data: const []);
      }
      throw ServerException('取得活動展演列表失敗：${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(e.message ?? '取得活動展演列表失敗');
    }
  }
}
