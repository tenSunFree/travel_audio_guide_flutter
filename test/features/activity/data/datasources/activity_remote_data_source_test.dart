import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/datasources/activity_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late ActivityRemoteDataSource dataSource;

  setUp(() {
    dio = MockDio();
    dataSource = ActivityRemoteDataSource(dio);
  });

  Response<Map<String, dynamic>> buildResponse({
    required int statusCode,
    Map<String, dynamic>? data,
  }) {
    return Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: '/zh-tw/Events/Activity'),
      statusCode: statusCode,
      data: data,
    );
  }

  group('ActivityRemoteDataSource.getActivities', () {
    test('200 且有資料時，正確解析成 ActivityPageModel', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => buildResponse(
          statusCode: 200,
          data: {
            'total': 2,
            'data': [
              {'id': 1, 'title': '活動A'},
              {'id': 2, 'title': '活動B'},
            ],
          },
        ),
      );
      final result = await dataSource.getActivities(lang: 'zh-tw', page: 1);
      expect(result.total, 2);
      expect(result.data.map((e) => e.title), ['活動A', '活動B']);
    });

    test('204 時回傳空清單，total 為 0', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => buildResponse(statusCode: 204));
      final result = await dataSource.getActivities(lang: 'zh-tw', page: 1);
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
        dataSource.getActivities(lang: 'zh-tw', page: 1),
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
          requestOptions: RequestOptions(path: '/zh-tw/Events/Activity'),
          message: '連線逾時',
        ),
      );
      await expectLater(
        dataSource.getActivities(lang: 'zh-tw', page: 1),
        throwsA(isA<ServerException>()),
      );
    });

    test('有帶 begin/end 時，query 參數會包含對應欄位', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async =>
            buildResponse(statusCode: 200, data: {'total': 0, 'data': []}),
      );
      await dataSource.getActivities(
        lang: 'zh-tw',
        page: 1,
        begin: '2026-01-01',
        end: '2026-01-31',
      );
      final captured =
          verify(
                () => dio.get<Map<String, dynamic>>(
                  any(),
                  queryParameters: captureAny(named: 'queryParameters'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['begin'], '2026-01-01');
      expect(captured['end'], '2026-01-31');
      expect(captured['page'], 1);
    });

    test('begin/end 未提供時，query 參數不會包含這兩個 key', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async =>
            buildResponse(statusCode: 200, data: {'total': 0, 'data': []}),
      );
      await dataSource.getActivities(lang: 'zh-tw', page: 1);
      final captured =
          verify(
                () => dio.get<Map<String, dynamic>>(
                  any(),
                  queryParameters: captureAny(named: 'queryParameters'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured.containsKey('begin'), isFalse);
      expect(captured.containsKey('end'), isFalse);
    });
  });
}
