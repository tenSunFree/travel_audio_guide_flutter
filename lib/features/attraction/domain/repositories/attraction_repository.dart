import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction_page.dart';

abstract class AttractionRepository {
  Future<AttractionPage> getAttractions({
    required String lang,
    required int page,
    String? categoryIds,
    double? nlat,
    double? elong,
  });

  Future<List<AttractionCategory>> getAttractionCategories({
    required String lang,
  });
}
