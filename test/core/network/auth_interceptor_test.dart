import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/network/auth_interceptor.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late AuthInterceptor interceptor;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    interceptor = AuthInterceptor(client);
  });

  group('onRequest', () {
    test('已登入時附加 Authorization header', () async {
      final session = MockSession();
      when(() => session.accessToken).thenReturn('token-123');
      when(() => auth.currentSession).thenReturn(session);
      final options = RequestOptions(
        path: '/api/v1/me',
      );
      final handler = RequestInterceptorHandler();
      interceptor.onRequest(options, handler);
      // There are no error propagation issues with the request handler,
      // Here we can directly verify the options.
      expect(
        options.headers['Authorization'],
        'Bearer token-123',
      );
    });

    test('未登入時不附加 Authorization header', () {
      when(() => auth.currentSession).thenReturn(null);
      final options = RequestOptions(
        path: '/api/v1/me',
      );
      final handler = RequestInterceptorHandler();
      interceptor.onRequest(options, handler);
      expect(
        options.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });

  group('401 handling', () {
    test('收到 401 時觸發 signOut()', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});
      final requestOptions = RequestOptions(
        path: '/api/v1/me',
      );
      final err = DioException(
        requestOptions: requestOptions,
        response: Response<void>(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );
      interceptor.handleUnauthorized(err);
      await Future<void>.delayed(Duration.zero);
      verify(() => auth.signOut()).called(1);
    });

    test('同時收到多個 401 只會觸發一次 signOut()', () async {
      final completer = Completer<void>();
      when(() => auth.signOut()).thenAnswer(
        (_) => completer.future,
      );
      final requestOptions = RequestOptions(
        path: '/api/v1/me',
      );
      final err = DioException(
        requestOptions: requestOptions,
        response: Response<void>(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );
      interceptor.handleUnauthorized(err);
      interceptor.handleUnauthorized(err);
      await Future<void>.delayed(Duration.zero);
      verify(() => auth.signOut()).called(1);
      completer.complete();
      await Future<void>.delayed(Duration.zero);
    });

    test('非 401 錯誤不會觸發 signOut()', () async {
      final requestOptions = RequestOptions(
        path: '/api/v1/me',
      );
      final err = DioException(
        requestOptions: requestOptions,
        response: Response<void>(
          requestOptions: requestOptions,
          statusCode: 500,
        ),
      );
      interceptor.handleUnauthorized(err);
      await Future<void>.delayed(Duration.zero);
      verifyNever(() => auth.signOut());
    });
  });
}
