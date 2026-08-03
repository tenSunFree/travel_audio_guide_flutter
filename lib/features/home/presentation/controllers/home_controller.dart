import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/features/home/di/home_providers.dart';
import 'package:flutter_travel_audio_guide/features/home/domain/entities/home_state.dart';

final homeControllerProvider = NotifierProvider<HomeController, HomeUiState>(
  HomeController.new,
);

class HomeController extends Notifier<HomeUiState> {
  StreamSubscription<HomeUiState>? _subscription;

  @override
  HomeUiState build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });
    final initial = HomeUiState.initial();
    _watchHomeState(
      period: initial.selectedPeriod,
      isRainyMode: initial.isRainyMode,
    );
    return initial;
  }

  void changePeriod(HomePeriod period) {
    state = state.copyWith(
      selectedPeriod: period,
      title: HomePeriodHelper.title(period),
      subtitle: HomePeriodHelper.subtitle(period),
      isLoading: true,
      errorMessage: null,
    );
    _watchHomeState(period: period, isRainyMode: state.isRainyMode);
  }

  void toggleRainyMode(bool value) {
    state = state.copyWith(
      isRainyMode: value,
      isLoading: true,
      errorMessage: null,
    );
    _watchHomeState(period: state.selectedPeriod, isRainyMode: value);
  }

  void _watchHomeState({
    required HomePeriod period,
    required bool isRainyMode,
  }) {
    _subscription?.cancel();
    final repository = ref.read(homeRepositoryProvider);
    _subscription = repository
        .watchHomeState(period: period, isRainyMode: isRainyMode)
        .listen(
          (newState) {
            state = newState;
          },
          onError: (Object error, StackTrace stackTrace) {
            state = state.copyWith(
              isLoading: false,
              errorMessage: error.toString(),
            );
          },
        );
  }
}
