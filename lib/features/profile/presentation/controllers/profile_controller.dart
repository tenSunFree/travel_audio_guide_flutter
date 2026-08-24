import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/profile/di/profile_providers.dart';
import 'package:flutter_travel_audio_guide/features/profile/domain/entities/profile.dart';

/// Attached to the authentication state:
/// - Signed in -> automatically call GET /api/v1/me once (the profile will be
///   created automatically if missing).
/// - Signed out -> clear the state.
class ProfileController extends AsyncNotifier<Profile?> {
  /// Monotonically increasing request sequence number.
  ///
  /// Both [updateProfile] and [refresh] are asynchronous operations; a user may
  /// trigger another request before the previous one completes (e.g. tapping
  /// update twice). The sequence number marks whether this call is the most
  /// recent one; only when it matches do we write the result into state, which
  /// prevents older responses from overwriting newer data.
  int _requestId = 0;

  @override
  Future<Profile?> build() async {
    final signedIn = await ref.watch(authStateChangesProvider.future);
    if (!signedIn) return null;
    return ref.read(profileRepositoryProvider).getMe();
  }

  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? preferredLanguage,
  }) async {
    final requestId = ++_requestId;
    state = const AsyncLoading<Profile?>().copyWithPrevious(state);
    final result = await AsyncValue.guard(
      () => ref
          .read(profileRepositoryProvider)
          .updateMe(
            displayName: displayName,
            avatarUrl: avatarUrl,
            preferredLanguage: preferredLanguage,
          ),
    );
    // If an updated request is sent during this waiting period, and the result of this request has expired, it will be discarded.
    // Let the latest request determine the final state.
    if (requestId != _requestId) return;
    // Directly use the guard result: success is AsyncData, failure is AsyncError.
    // Don't swallow the error here and replace it with the old data—the UI needs to know that the update truly failed.
    state = result;
  }

  Future<void> refresh() async {
    final requestId = ++_requestId;
    state = const AsyncLoading<Profile?>().copyWithPrevious(state);
    final result = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).getMe(),
    );
    if (requestId != _requestId) return;
    state = result;
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, Profile?>(
      ProfileController.new,
    );
