import 'package:flutter_travel_audio_guide/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/entities/app_user.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final SupabaseAuthDataSource _dataSource;

  @override
  AppUser? get currentUser {
    final user = _dataSource.currentUser;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email);
  }

  @override
  bool get isSignedIn => _dataSource.currentSession != null;

  @override
  Stream<bool> get authStateChanges =>
      _dataSource.onAuthStateChange.map((state) => state.session != null);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _dataSource.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) {
    return _dataSource.signUpWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _dataSource.signOut();
}
