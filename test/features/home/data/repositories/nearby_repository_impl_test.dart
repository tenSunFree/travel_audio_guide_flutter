import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/home/data/datasources/nearby_local_data_source.dart';
import 'package:flutter_travel_audio_guide/features/home/data/repositories/nearby_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockNearbyLocalDataSource extends Mock implements NearbyLocalDataSource {}

void main() {
  late MockNearbyLocalDataSource localDataSource;
  late NearbyRepositoryImpl repository;

  setUp(() {
    localDataSource = MockNearbyLocalDataSource();
    repository = NearbyRepositoryImpl(localDataSource);
  });

  test('isNearbyEnabled 直接回傳 local data source 的結果', () {
    when(() => localDataSource.getNearbyEnabled()).thenReturn(true);
    expect(repository.isNearbyEnabled(), isTrue);
    when(() => localDataSource.getNearbyEnabled()).thenReturn(false);
    expect(repository.isNearbyEnabled(), isFalse);
  });

  test('setNearbyEnabled 會把值原封不動轉交給 local data source', () async {
    when(
      () => localDataSource.setNearbyEnabled(any()),
    ).thenAnswer((_) async {});
    await repository.setNearbyEnabled(true);
    verify(() => localDataSource.setNearbyEnabled(true)).called(1);
  });
}
