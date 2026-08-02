import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity_page.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/repositories/activity_repository.dart';

class GetActivitiesUseCase {
  const GetActivitiesUseCase(this._repository);

  final ActivityRepository _repository;

  Future<ActivityPage> call({
    required String lang,
    required int page,
    String? begin,
    String? end,
  }) {
    return _repository.getActivities(
      lang: lang,
      page: page,
      begin: begin,
      end: end,
    );
  }
}
