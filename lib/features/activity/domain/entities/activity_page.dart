import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_page.freezed.dart';

@freezed
abstract class ActivityPage with _$ActivityPage {
  const factory ActivityPage({
    required int total,
    required int page,
    required List<Activity> items,
    required bool hasMore,
  }) = _ActivityPage;
}
