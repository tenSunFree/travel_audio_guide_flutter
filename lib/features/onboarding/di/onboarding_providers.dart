import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/core/preferences/shared_preferences_provider.dart';
import 'package:flutter_travel_audio_guide/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:flutter_travel_audio_guide/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/onboarding/domain/repositories/onboarding_repository.dart';

final onboardingLocalDataSourceProvider = Provider<OnboardingLocalDataSource>((
  ref,
) {
  return OnboardingLocalDataSource(ref.watch(sharedPreferencesProvider));
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(ref.watch(onboardingLocalDataSourceProvider));
});

/// Use Notifier to manage the status of "whether the welcome page has been viewed".
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(onboardingRepositoryProvider).hasSeenWelcome();
  }

  Future<void> completeOnboarding() async {
    await ref.read(onboardingRepositoryProvider).completeOnboarding();
    // Modifying the state triggers ref.listen, and then GoRouter refreshListenable completes the URL redirection.
    // WelcomePage does not need to call context.go() itself.
    state = true;
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
