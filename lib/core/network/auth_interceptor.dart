import 'package:dio/dio.dart';
import 'package:flutter_travel_audio_guide/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// For every request sent to the Go backend (/api/v1/*),
/// automatically attach the current Supabase session's access token.
///
/// Flow:
/// Flutter -> Supabase Auth sign-in -> obtain access_token
///   -> call Go Backend API -> include `Authorization: Bearer <access_token>` header
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._client);

  final SupabaseClient _client;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Supabase SDK automatically refreshes tokens in the background,
    // so currentSession.accessToken should be up-to-date.
    final accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    } else {
      AppLogger.info(
        '[AuthInterceptor] Not signed in, Authorization header not added'
        ' | path=${options.path}',
      );
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 indicates the token may be invalid (e.g., user logged out on another device or refresh token expired).
    // We only log it here and don't perform global sign-out inside the interceptor,
    // to avoid conflicting with UI-layer error handling or navigation.
    if (err.response?.statusCode == 401) {
      AppLogger.info(
        '[AuthInterceptor] Received 401, token may be invalid'
        ' | path=${err.requestOptions.path}',
      );
    }
    handler.next(err);
  }
}
