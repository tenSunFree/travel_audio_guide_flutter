import 'package:flutter_travel_audio_guide/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:flutter_travel_audio_guide/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._localDataSource);

  final OnboardingLocalDataSource _localDataSource;

  @override
  bool hasSeenWelcome() => _localDataSource.hasSeenWelcome();

  @override
  Future<void> completeOnboarding() => _localDataSource.markWelcomeAsSeen();
}
