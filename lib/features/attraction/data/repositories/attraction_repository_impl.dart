import 'package:flutter_travel_audio_guide/features/attraction/data/datasources/attraction_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction_page.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/repositories/attraction_repository.dart';

class AttractionRepositoryImpl implements AttractionRepository {
  const AttractionRepositoryImpl(this._remoteDataSource);

  final AttractionRemoteDataSource _remoteDataSource;

  @override
  Future<AttractionPage> getAttractions({
    required String lang,
    required int page,
    String? categoryIds,
    double? nlat,
    double? elong,
  }) async {
    final model = await _remoteDataSource.getAttractions(
      lang: lang,
      page: page,
      categoryIds: categoryIds,
      nlat: nlat,
      elong: elong,
    );
    return model.toEntity();
  }

  @override
  Future<List<AttractionCategory>> getAttractionCategories({
    required String lang,
  }) async {
    final models = await _remoteDataSource.getAttractionCategories(lang: lang);
    return models.map((e) => e.toEntity()).toList();
  }
}
