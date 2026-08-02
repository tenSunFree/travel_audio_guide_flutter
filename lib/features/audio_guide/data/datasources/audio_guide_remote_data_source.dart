import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/models/audio_guide_page_model.dart';

class DownloadedAudioBinary {
  const DownloadedAudioBinary({
    required this.bytes,
    required this.contentType,
    required this.finalUrl,
  });

  final Uint8List bytes;
  final String contentType;
  final String finalUrl;
}

class AudioGuideRemoteDataSource {
  const AudioGuideRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AudioGuidePageModel> getAudioGuides({
    required String lang,
    required int page,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/$lang/Media/Audio',
        queryParameters: {'page': page},
      );
      if (response.statusCode == 200 && response.data != null) {
        return AudioGuidePageModel.fromJson(response.data!, page);
      }
      if (response.statusCode == 204) {
        return AudioGuidePageModel(total: 0, page: page, data: const []);
      }
      throw ServerException('取得語音列表失敗：${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(e.message ?? '取得語音列表失敗');
    }
  }

  Future<DownloadedAudioBinary> downloadAudioBinary(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {'accept': '*/*'},
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const DownloadException('下載內容為空');
      }
      final contentTypeHeader =
          response.headers.value(Headers.contentTypeHeader) ?? '';
      return DownloadedAudioBinary(
        bytes: Uint8List.fromList(bytes),
        contentType: contentTypeHeader,
        finalUrl: response.realUri.toString(),
      );
    } on DioException catch (e) {
      throw DownloadException(e.message ?? '下載音訊失敗');
    }
  }
}
