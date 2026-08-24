import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Flutter's GoTrueClient so upper layers (Repository)
/// don't need to depend directly on supabase_flutter types.
class SupabaseAuthDataSource {
  const SupabaseAuthDataSource(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  /// Emits when the session changes (sign-in, sign-out, token refresh).
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      AppLogger.error('SupabaseAuth signIn failed: ${e.message}', exception: e);
      throw ServerException(_mapAuthError(e));
    }
  }

  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      AppLogger.error('SupabaseAuth signUp failed: ${e.message}', exception: e);
      throw ServerException(_mapAuthError(e));
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      AppLogger.error(
        'SupabaseAuth signOut failed: ${e.message}',
        exception: e,
      );
      throw ServerException(e.message);
    }
  }

  /// Map common Supabase error codes to user-friendly messages for UI display.
  String _mapAuthError(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return '帳號或密碼錯誤';
      case 'email_not_confirmed':
        return '請先完成信箱驗證';
      case 'user_already_exists':
        return '此信箱已被註冊';
      case 'weak_password':
        return '密碼強度不足（至少 6 碼）';
      default:
        return e.message;
    }
  }
}
