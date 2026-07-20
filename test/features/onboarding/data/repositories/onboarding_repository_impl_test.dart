import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:flutter_travel_audio_guide/features/onboarding/data/repositories/onboarding_repository_impl.dart';

class MockOnboardingLocalDataSource extends Mock
    implements OnboardingLocalDataSource {}

void main() {
  late MockOnboardingLocalDataSource localDataSource;
  late OnboardingRepositoryImpl repository;

  setUp(() {
    localDataSource = MockOnboardingLocalDataSource();
    repository = OnboardingRepositoryImpl(localDataSource);
  });

  test('hasSeenWelcome 直接回傳 local data source 的結果', () {
    when(() => localDataSource.hasSeenWelcome()).thenReturn(true);
    expect(repository.hasSeenWelcome(), isTrue);
    when(() => localDataSource.hasSeenWelcome()).thenReturn(false);
    expect(repository.hasSeenWelcome(), isFalse);
  });

  test('completeOnboarding 會呼叫 local data source 標記為已看過', () async {
    when(() => localDataSource.markWelcomeAsSeen()).thenAnswer((_) async {});
    await repository.completeOnboarding();
    verify(() => localDataSource.markWelcomeAsSeen()).called(1);
  });
}
