import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/network/dio_log_filter.dart';

void main() {
  group('DioLogFilter', () {
    test('shouldLogRequest 對一般路徑回傳 true', () {
      final options = RequestOptions(path: '/Attractions/List');
      expect(DioLogFilter.shouldLogRequest(options), true);
    });

    test('shouldLogResponse 對一般路徑回傳 true', () {
      final options = RequestOptions(path: '/Home/Recommend');
      final response = Response(requestOptions: options);
      expect(DioLogFilter.shouldLogResponse(response), true);
    });

    test('shouldLogError 對一般路徑回傳 true', () {
      final options = RequestOptions(path: '/Reminder/Create');
      final error = DioException(requestOptions: options);
      expect(DioLogFilter.shouldLogError(error), true);
    });
  });
}
