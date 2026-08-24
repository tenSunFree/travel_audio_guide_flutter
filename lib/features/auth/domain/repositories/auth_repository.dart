import 'package:flutter_travel_audio_guide/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  /// Currently signed-in user; null when not signed in.
  AppUser? get currentUser;

  /// Whether the user is signed in (has a valid session).
  bool get isSignedIn;

  /// Stream of sign-in/sign-out state changes, used by the router to automatically redirect.
  Stream<bool> get authStateChanges;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signUpWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
