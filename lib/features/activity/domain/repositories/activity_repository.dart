import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity_page.dart';

abstract class ActivityRepository {
  Future<ActivityPage> getActivities({
    required String lang,
    required int page,
    String? begin,
    String? end,
  });
}
