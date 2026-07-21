import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/audio_guide_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late AudioGuideRemoteDataSource dataSource;

  setUp(() {
    dio = MockDio();
    dataSource = AudioGuideRemoteDataSource(dio);
  });

  group('AudioGuideRemoteDataSource.getAudioGuides', () {
    Response<Map<String, dynamic>> buildResponse({
      required int statusCode,
      Map<String, dynamic>? data,
    }) {
      return Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/zh-tw/Media/Audio'),
        statusCode: statusCode,
        data: data,
      );
    }

    test('200 且有資料時，正確解析成 AudioGuidePageModel', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => buildResponse(
          statusCode: 200,
          data: {
            'total': 1,
            'data': [
              {'id': 1, 'title': '故宮導覽'},
            ],
          },
        ),
      );
      final result = await dataSource.getAudioGuides(lang: 'zh-tw', page: 1);
      expect(result.total, 1);
      expect(result.data.single.title, '故宮導覽');
    });

    test('204 時回傳空清單', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => buildResponse(statusCode: 204));
      final result = await dataSource.getAudioGuides(lang: 'zh-tw', page: 1);
      expect(result.total, 0);
      expect(result.data, isEmpty);
    });

    test('非 200/204 狀態碼會拋出 ServerException', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => buildResponse(statusCode: 500));
      await expectLater(
        dataSource.getAudioGuides(lang: 'zh-tw', page: 1),
        throwsA(isA<ServerException>()),
      );
    });

    test('Dio 例外會轉換成 ServerException', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/zh-tw/Media/Audio'),
          message: '逾時',
        ),
      );
      await expectLater(
        dataSource.getAudioGuides(lang: 'zh-tw', page: 1),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('AudioGuideRemoteDataSource.downloadAudioBinary', () {
    const url = 'https://example.com/audio/1.mp3';

    test('下載成功時回傳 bytes / contentType / finalUrl', () async {
      when(
        () => dio.get<List<int>>(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          requestOptions: RequestOptions(path: url),
          statusCode: 200,
          data: [1, 2, 3, 4],
          headers: Headers.fromMap({
            Headers.contentTypeHeader: ['audio/mpeg'],
          }),
        ),
      );
      final result = await dataSource.downloadAudioBinary(url);
      expect(result.bytes, [1, 2, 3, 4]);
      expect(result.contentType, 'audio/mpeg');
    });

    test('回傳內容為空 bytes 時拋出 DownloadException', () async {
      when(
        () => dio.get<List<int>>(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          requestOptions: RequestOptions(path: url),
          statusCode: 200,
          data: const <int>[],
        ),
      );
      await expectLater(
        dataSource.downloadAudioBinary(url),
        throwsA(isA<DownloadException>()),
      );
    });

    test('回傳內容為 null 時拋出 DownloadException', () async {
      when(
        () => dio.get<List<int>>(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          requestOptions: RequestOptions(path: url),
          statusCode: 200,
          data: null,
        ),
      );
      await expectLater(
        dataSource.downloadAudioBinary(url),
        throwsA(isA<DownloadException>()),
      );
    });

    test('Dio 例外會轉換成 DownloadException', () async {
      when(
        () => dio.get<List<int>>(any(), options: any(named: 'options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: url),
          message: '下載失敗',
        ),
      );
      await expectLater(
        dataSource.downloadAudioBinary(url),
        throwsA(isA<DownloadException>()),
      );
    });
  });
}
