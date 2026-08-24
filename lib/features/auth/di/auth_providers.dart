import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:flutter_travel_audio_guide/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase.initialize() is already executed in bootstrap.dart;
/// use the global singleton client here.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final supabaseAuthDataSourceProvider = Provider<SupabaseAuthDataSource>((
  ref,
) {
  return SupabaseAuthDataSource(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseAuthDataSourceProvider));
});

/// Stream of sign-in state changes: true = signed in, false = signed out.
/// GoRouter's refreshListenable depends on this provider to automatically redirect.
final authStateChangesProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  // Emit the current state immediately to avoid having no value when the app starts.
  return repo.authStateChanges.startWith(repo.isSignedIn);
});

/// Synchronous snapshot whether the user is signed in, used by the UI
/// (e.g., to show sign in/out button).
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).isSignedIn;
});

extension _StartWith<T> on Stream<T> {
  /// Stream doesn't include startWith natively; implement a simple version
  /// here to avoid adding rxdart as a dependency.
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
