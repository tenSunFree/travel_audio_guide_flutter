import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/profile/di/profile_providers.dart';
import 'package:flutter_travel_audio_guide/features/profile/domain/entities/profile.dart';

/// Attached to the authentication state:
/// - When sign-in succeeds -> automatically call GET /api/v1/me (the backend will create a profile if none exists).
/// - When sign-out -> clear the state.
class ProfileController extends AsyncNotifier<Profile?> {
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
    final current = state.valueOrNull;
    state = const AsyncLoading<Profile?>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final updated = await ref
          .read(profileRepositoryProvider)
          .updateMe(
            displayName: displayName,
            avatarUrl: avatarUrl,
            preferredLanguage: preferredLanguage,
          );
      return updated;
    });
    // Revert to previous data on failure to avoid clearing the UI.
    if (state.hasError && current != null) {
      state = AsyncData<Profile?>(current);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Profile?>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).getMe(),
    );
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, Profile?>(
      ProfileController.new,
    );
