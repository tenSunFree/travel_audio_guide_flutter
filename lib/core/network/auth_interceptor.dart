import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_travel_audio_guide/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Automatically attaches the current Supabase session access_token to
/// every request sent to the Go backend (e.g. /api/v1/*).
///
/// Flow:
/// Flutter -> Supabase Auth sign-in -> obtain access_token
///   -> call Go backend API -> include `Authorization: Bearer <access_token>` header
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._client);

  final SupabaseClient _client;

  /// Prevent multiple concurrent requests receiving 401 from triggering
  /// repeated signOut() calls.
  bool _isHandlingUnauthorized = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // The Supabase SDK automatically refreshes expiring tokens in the
    // background, so the access_token from currentSession is always up-to-date.
    final accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    } else {
      AppLogger.info(
        '[AuthInterceptor] 尚未登入，未帶入 Authorization header'
        ' | path=${options.path}',
      );
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 indicates the token is invalid (for example, the user signed out on
    // another device, or the refresh token expired). Trigger a real signOut()
    // here so:
    // - authStateChangesProvider receives the new state and GoRouter's
    //   redirect will navigate to the login page automatically
    // - avoid manipulating navigation directly here to prevent conflicts with
    //   UI-level error handling and navigation logic
    if (err.response?.statusCode == 401) {
      _handleUnauthorized(err.requestOptions.path);
    }
    handler.next(err);
  }

  void _handleUnauthorized(String path) {
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;
    AppLogger.info(
      '[AuthInterceptor] Received 401, forcing sign out | path=$path',
    );
    unawaited(
      _client.auth
          .signOut()
          .catchError((Object e, StackTrace st) {
            AppLogger.error(
              '[AuthInterceptor] signOut() failed after receiving 401',
              exception: e,
              stackTrace: st,
            );
          })
          .whenComplete(() => _isHandlingUnauthorized = false),
    );
  }
}
