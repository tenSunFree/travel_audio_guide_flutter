import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/home/data/repositories/home_repository.dart';
import 'package:flutter_travel_audio_guide/features/home/di/home_providers.dart';
import 'package:flutter_travel_audio_guide/features/home/domain/entities/home_state.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/controllers/home_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

HomeUiState _buildState({
  required HomePeriod period,
  bool isRainyMode = false,
}) {
  return HomeUiState(
    selectedPeriod: period,
    isRainyMode: isRainyMode,
    title: 'title-${period.name}',
    subtitle: 'subtitle-${period.name}',
    heroCard: null,
    nearbyCards: const [],
    activityCards: const [],
    availableCards: const [],
    isLoading: false,
    errorMessage: null,
  );
}

void main() {
  late MockHomeRepository repository;
  late Map<int, StreamController<HomeUiState>> streams;
  late int callCount;
  late ProviderContainer container;

  setUpAll(() {
    // HomePeriod is a custom enum. When using any() or captureAny()
    // to match this type inside when()/verify(), mocktail requires a
    // registered fallback value. Otherwise it throws the
    // "registerFallbackValue was not previously called" exception.
    registerFallbackValue(HomePeriod.morning);
  });

  setUp(() {
    repository = MockHomeRepository();
    streams = {};
    callCount = 0;
    // Create a new StreamController for each watchHomeState call so we
    // can control events sent to each subscription independently
    // (simulates the Repository returning a new stream on each subscription).
    when(
      () => repository.watchHomeState(
        period: any(named: 'period'),
        isRainyMode: any(named: 'isRainyMode'),
      ),
    ).thenAnswer((_) {
      callCount++;
      final controller = StreamController<HomeUiState>();
      streams[callCount] = controller;
      return controller.stream;
    });
    container = ProviderContainer(
      overrides: [homeRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  tearDown(() async {
    for (final c in streams.values) {
      await c.close();
    }
  });

  group('HomeController', () {
    test(
      'build() 回傳 HomeUiState.initial()，並依初始 period 訂閱一次 watchHomeState',
      () {
        final state = container.read(homeControllerProvider);
        final initial = HomeUiState.initial();
        expect(state.selectedPeriod, initial.selectedPeriod);
        expect(state.isRainyMode, initial.isRainyMode);
        expect(state.isLoading, isTrue);
        expect(callCount, 1);
      },
    );

    test('watchHomeState 發出新資料時，state 會被整個取代', () async {
      container.read(
        homeControllerProvider,
      ); // triggers creation and corresponds to streams[1]
      final newState = _buildState(period: HomePeriod.afternoon);
      streams[1]!.add(newState);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(homeControllerProvider), newState);
    });

    test('watchHomeState 發生錯誤時，只更新 isLoading/errorMessage，其餘欄位保留原狀', () async {
      final beforeError = container.read(homeControllerProvider);
      streams[1]!.addError(Exception('讀取失敗'));
      await Future<void>.delayed(Duration.zero);
      final state = container.read(homeControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('讀取失敗'));
      expect(state.selectedPeriod, beforeError.selectedPeriod);
      expect(state.isRainyMode, beforeError.isRainyMode);
    });

    test('changePeriod 會更新 title/subtitle/isLoading，並重新訂閱新的 period', () async {
      container.read(homeControllerProvider);
      final _ = container.read(homeControllerProvider.notifier)
        ..changePeriod(HomePeriod.evening);
      final state = container.read(homeControllerProvider);
      expect(state.selectedPeriod, HomePeriod.evening);
      expect(state.isLoading, isTrue);
      expect(state.errorMessage, isNull);
      // Use captured values instead of hard-coding call indices to assert
      // on specific parameters. This avoids false negatives when the
      // initial period (which depends on the system time) happens to be evening.
      final captured = verify(
        () => repository.watchHomeState(
          period: captureAny(named: 'period'),
          isRainyMode: captureAny(named: 'isRainyMode'),
        ),
      ).captured;
      expect(callCount, 2);
      expect(captured[captured.length - 2], HomePeriod.evening);
      expect(captured.last, isFalse);
    });

    test('changePeriod 後，舊的訂閱已取消，不會再影響 state', () async {
      container.read(homeControllerProvider);
      final _ = container.read(homeControllerProvider.notifier)
        ..changePeriod(HomePeriod.evening);
      final stateAfterChange = container.read(homeControllerProvider);
      // The old stream (#1) emitting new data should not affect the current state
      streams[1]!.add(_buildState(period: HomePeriod.morning));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(homeControllerProvider), stateAfterChange);
    });

    test('toggleRainyMode 會更新 isRainyMode/isLoading，並重新訂閱', () async {
      container.read(homeControllerProvider);
      final _ = container.read(homeControllerProvider.notifier)
        ..toggleRainyMode(true);
      final state = container.read(homeControllerProvider);
      expect(state.isRainyMode, isTrue);
      expect(state.isLoading, isTrue);
      expect(callCount, 2);
      final captured = verify(
        () => repository.watchHomeState(
          period: captureAny(named: 'period'),
          isRainyMode: captureAny(named: 'isRainyMode'),
        ),
      ).captured;
      expect(captured.last, isTrue);
    });
  });
}
