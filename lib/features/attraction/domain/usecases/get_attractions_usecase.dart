import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction_page.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/repositories/attraction_repository.dart';

class GetAttractionsUseCase {
  const GetAttractionsUseCase(this._repository);

  final AttractionRepository _repository;

  Future<AttractionPage> call({
    required int page,
    String lang = 'zh-tw',
    String? categoryIds,
    double? nlat,
    double? elong,
  }) {
    return _repository.getAttractions(
      lang: lang,
      page: page,
      categoryIds: categoryIds,
      nlat: nlat,
      elong: elong,
    );
  }
}
