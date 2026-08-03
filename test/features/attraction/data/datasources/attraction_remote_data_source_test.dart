import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/datasources/attraction_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late AttractionRemoteDataSource dataSource;

  setUp(() {
    dio = MockDio();
    dataSource = AttractionRemoteDataSource(dio);
  });

  Response<Map<String, dynamic>> buildMapResponse({
    required int statusCode,
    Map<String, dynamic>? data,
  }) {
    return Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: '/zh-tw/Attractions/All'),
      statusCode: statusCode,
      data: data,
    );
  }

  group('AttractionRemoteDataSource.getAttractions', () {
    test('200 且有資料時，正確解析成 AttractionPageModel', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => buildMapResponse(
          statusCode: 200,
          data: {
            'total': 2,
            'data': [
              {'id': 1, 'name': '故宮博物院'},
              {'id': 2, 'name': '台北101'},
            ],
          },
        ),
      );
      final result = await dataSource.getAttractions(lang: 'zh-tw', page: 1);
      expect(result.total, 2);
      expect(result.data.map((e) => e.name), ['故宮博物院', '台北101']);
    });

    test('204 時回傳空清單', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => buildMapResponse(statusCode: 204));
      final result = await dataSource.getAttractions(lang: 'zh-tw', page: 1);
      expect(result.total, 0);
      expect(result.data, isEmpty);
    });

    test('非 200/204 狀態碼會拋出 ServerException', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => buildMapResponse(statusCode: 500));
      await expectLater(
        dataSource.getAttractions(lang: 'zh-tw', page: 1),
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
          requestOptions: RequestOptions(path: '/zh-tw/Attractions/All'),
          message: '連線逾時',
        ),
      );
      await expectLater(
        dataSource.getAttractions(lang: 'zh-tw', page: 1),
        throwsA(isA<ServerException>()),
      );
    });

    test('有帶 categoryIds/nlat/elong 時會加進 query', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => buildMapResponse(
          statusCode: 200,
          data: {
            'total': 0,
            'data': <Map<String, dynamic>>[],
          },
        ),
      );
      await dataSource.getAttractions(
        lang: 'zh-tw',
        page: 1,
        categoryIds: '1,2',
        nlat: 25.03,
        elong: 121.56,
      );
      final captured =
          verify(
                () => dio.get<Map<String, dynamic>>(
                  any(),
                  queryParameters: captureAny(named: 'queryParameters'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['categoryIds'], '1,2');
      expect(captured['nlat'], 25.03);
      expect(captured['elong'], 121.56);
    });

    test('categoryIds 為空字串時不會加進 query', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => buildMapResponse(
          statusCode: 200,
          data: {
            'total': 0,
            'data': <Map<String, dynamic>>[],
          },
        ),
      );
      await dataSource.getAttractions(lang: 'zh-tw', page: 1, categoryIds: '');
      final captured =
          verify(
                () => dio.get<Map<String, dynamic>>(
                  any(),
                  queryParameters: captureAny(named: 'queryParameters'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured.containsKey('categoryIds'), isFalse);
    });
  });

  group('AttractionRemoteDataSource.getAttractionCategories', () {
    test('回傳格式為 {"data": [...]} 時能正確解析，並濾掉 id=0 或名稱空白的分類', () async {
      when(() => dio.get<dynamic>(any())).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(
            path: '/zh-tw/Miscellaneous/Categories',
          ),
          statusCode: 200,
          data: {
            'data': [
              {'id': 1, 'name': '博物館'},
              {'id': 0, 'name': '應該被濾掉'},
              {'id': 2, 'name': ''},
            ],
          },
        ),
      );
      final result = await dataSource.getAttractionCategories(lang: 'zh-tw');
      expect(result.map((e) => e.id), [1]);
      expect(result.single.name, '博物館');
    });

    test('回傳格式為 {"categories": [...]} 時也能正確解析', () async {
      when(() => dio.get<dynamic>(any())).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(
            path: '/zh-tw/Miscellaneous/Categories',
          ),
          statusCode: 200,
          data: {
            'categories': [
              {'id': 3, 'name': '戶外踏青'},
            ],
          },
        ),
      );
      final result = await dataSource.getAttractionCategories(lang: 'zh-tw');
      expect(result.single.id, 3);
    });

    test('回傳格式直接是 List 時也能正確解析', () async {
      when(() => dio.get<dynamic>(any())).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(
            path: '/zh-tw/Miscellaneous/Categories',
          ),
          statusCode: 200,
          data: [
            {'id': 4, 'name': '主題商街'},
          ],
        ),
      );
      final result = await dataSource.getAttractionCategories(lang: 'zh-tw');
      expect(result.single.id, 4);
    });

    test('非 200 或格式不符合預期時，回傳空清單', () async {
      when(() => dio.get<dynamic>(any())).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(
            path: '/zh-tw/Miscellaneous/Categories',
          ),
          statusCode: 500,
        ),
      );
      final result = await dataSource.getAttractionCategories(lang: 'zh-tw');
      expect(result, isEmpty);
    });

    test('Dio 例外會轉換成 ServerException', () async {
      when(() => dio.get<dynamic>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/zh-tw/Miscellaneous/Categories',
          ),
          message: '連線失敗',
        ),
      );
      await expectLater(
        dataSource.getAttractionCategories(lang: 'zh-tw'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
