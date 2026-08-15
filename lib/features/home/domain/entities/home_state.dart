import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_state.freezed.dart';

enum HomePeriod { morning, afternoon, evening, night }

enum RecommendStatus {
  openNow,
  openUntil,
  alwaysOpen,
  ongoing,
  comingSoon,
  closingSoon,
  uncertain,
}

enum HomeRecommendType { attraction, activity, audioGuide }

@freezed
abstract class HomeRecommendCard with _$HomeRecommendCard {
  const factory HomeRecommendCard({
    required String id,
    required String title,
    required String subtitle,
    required String? imageUrl,
    required String badgeText,
    required String? distanceText,
    required String? reasonText,
    required RecommendStatus status,
    required double? lat,
    required double? lng,
    required HomeRecommendType type,
    required String emoji,
    Attraction? attraction,
    Activity? activity,
  }) = _HomeRecommendCard;
}

@freezed
abstract class HomeUiState with _$HomeUiState {
  const factory HomeUiState({
    required HomePeriod selectedPeriod,
    required bool isRainyMode,
    required String title,
    required String subtitle,
    required HomeRecommendCard? heroCard,
    required List<HomeRecommendCard> nearbyCards,
    required List<HomeRecommendCard> activityCards,
    required List<HomeRecommendCard> availableCards,
    required bool isLoading,
    required String? errorMessage,
  }) = _HomeUiState;
  const HomeUiState._();

  factory HomeUiState.initial() {
    final period = HomePeriodHelper.fromNow(DateTime.now());
    return HomeUiState(
      selectedPeriod: period,
      isRainyMode: false,
      title: HomePeriodHelper.title(period),
      subtitle: HomePeriodHelper.subtitle(period),
      heroCard: null,
      nearbyCards: const [],
      activityCards: const [],
      availableCards: const [],
      isLoading: true,
      errorMessage: null,
    );
  }
}

extension HomePeriodHelper on HomePeriod {
  static HomePeriod fromNow(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return HomePeriod.morning;
    if (hour >= 12 && hour < 17) return HomePeriod.afternoon;
    if (hour >= 17 && hour < 20) return HomePeriod.evening;
    return HomePeriod.night;
  }

  static String label(HomePeriod period) {
    return switch (period) {
      HomePeriod.morning => '早上',
      HomePeriod.afternoon => '下午',
      HomePeriod.evening => '傍晚',
      HomePeriod.night => '夜間',
    };
  }

  static String title(HomePeriod period) {
    return switch (period) {
      HomePeriod.morning => '早安，今天想去哪走走？',
      HomePeriod.afternoon => '午後適合看展或散步',
      HomePeriod.evening => '傍晚，台北開始亮起來',
      HomePeriod.night => '夜晚，台北最美的時刻',
    };
  }

  static String subtitle(HomePeriod period) {
    return switch (period) {
      HomePeriod.morning => '適合晨間散步、步道與戶外景點',
      HomePeriod.afternoon => '為你整理現在適合安排的景點',
      HomePeriod.evening => '適合河岸、夕陽、夜市與晚間活動',
      HomePeriod.night => '夜市人聲鼎沸・夜景景點也正適合出發',
    };
  }
}
