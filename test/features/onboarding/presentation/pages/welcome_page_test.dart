import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/onboarding/di/onboarding_providers.dart';
import 'package:flutter_travel_audio_guide/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter_travel_audio_guide/features/onboarding/presentation/pages/welcome_page.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({
    this.initiallyCompleted = false,
    this.completeDelay = Duration.zero,
  });

  final bool initiallyCompleted;
  final Duration completeDelay;
  var completeCallCount = 0;

  @override
  bool hasSeenWelcome() => initiallyCompleted;

  @override
  Future<void> completeOnboarding() async {
    completeCallCount++;
    if (completeDelay != Duration.zero) {
      await Future<void>.delayed(completeDelay);
    }
  }
}

Widget buildSubject(FakeOnboardingRepository repository) {
  return ProviderScope(
    overrides: [onboardingRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: WelcomePage()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('完整顯示歡迎頁主要內容', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = FakeOnboardingRepository();
    await tester.pumpWidget(buildSubject(repository));
    // Entrance animation lasts 1400ms; advance time to finish the animation and avoid intermediate states.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.text('開始探索'), findsOneWidget);
    expect(find.text('TAIPEI'), findsOneWidget);
    expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
  });

  testWidgets('點擊開始探索會完成 onboarding', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = FakeOnboardingRepository();
    await tester.pumpWidget(buildSubject(repository));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.tap(find.text('開始探索'));
    await tester.pumpAndSettle();
    expect(repository.completeCallCount, 1);
  });

  testWidgets('送出期間顯示準備中並防止重複送出', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = FakeOnboardingRepository(
      completeDelay: const Duration(milliseconds: 500),
    );
    await tester.pumpWidget(buildSubject(repository));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.tap(find.text('開始探索'));
    await tester.pump();
    expect(find.text('準備中...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The button is disabled (onPressed is null); tapping again should not trigger a second call.
    await tester.tap(find.text('準備中...'));
    await tester.pump();
    expect(repository.completeCallCount, 1);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('開始探索'), findsOneWidget);
  });
}
