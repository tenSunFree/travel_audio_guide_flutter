import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/models/attraction_model.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  AttractionModel buildModel({
    int id = 1,
    String name = '故宮博物院',
    String modified = '2026-01-01',
    List<AttractionCategoryModel> categories = const [],
    List<AttractionImageModel> images = const [],
    List<AttractionTagModel> friendlies = const [],
    double? nlat,
    double? elong,
  }) {
    return AttractionModel(
      id: id,
      name: name,
      introduction: '介紹文字',
      openTime: '09:00-17:00',
      distric: '士林區',
      address: '台北市士林區',
      tel: '02-1234-5678',
      nlat: nlat,
      elong: elong,
      officialSite: 'https://example.com',
      ticket: '免費',
      modified: modified,
      categories: categories,
      friendlies: friendlies,
      images: images,
    );
  }

  group('AttractionDao.upsertAll / getAll', () {
    test('寫入後可以完整讀回基本欄位', () async {
      await db.attractionDao.upsertAll([buildModel()]);
      final all = await db.attractionDao.getAll();
      expect(all, hasLength(1));
      expect(all.single.name, '故宮博物院');
      expect(all.single.address, '台北市士林區');
    });

    test('categories / images / friendlies 會正確序列化並可還原', () async {
      await db.attractionDao.upsertAll([
        buildModel(
          categories: const [AttractionCategoryModel(id: 10, name: '博物館')],
          images: const [
            AttractionImageModel(src: 'https://example.com/a.png'),
          ],
          friendlies: const [AttractionTagModel(id: 392, name: '無障礙')],
        ),
      ]);
      final entity = await db.attractionDao.findById(1);
      expect(entity, isNotNull);
      expect(entity!.categories.single.id, 10);
      expect(entity.categories.single.name, '博物館');
      expect(entity.images.single.src, 'https://example.com/a.png');
      expect(entity.friendlies.single.id, 392);
    });

    test('相同 id 再次 upsert 會更新既有資料，而不是新增一筆', () async {
      await db.attractionDao.upsertAll([
        buildModel(name: '舊名稱'),
      ]);
      await db.attractionDao.upsertAll([
        buildModel(name: '新名稱', modified: '2026-02-01'),
      ]);
      final all = await db.attractionDao.getAll();
      expect(all, hasLength(1));
      expect(all.single.name, '新名稱');
    });

    test('nlat / elong 為 null 時可以正確寫入與讀出', () async {
      await db.attractionDao.upsertAll([
        buildModel(),
      ]);
      final entity = await db.attractionDao.findById(1);
      expect(entity!.nlat, isNull);
      expect(entity.elong, isNull);
    });
  });

  group('AttractionDao.watchAll', () {
    test('依名稱字典序升冪排序', () async {
      await db.attractionDao.upsertAll([
        buildModel(name: 'Zebra'),
        buildModel(id: 2, name: 'Apple'),
      ]);
      final list = await db.attractionDao.watchAll().first;
      expect(list.map((a) => a.name), ['Apple', 'Zebra']);
    });
  });

  group('AttractionDao.findByName', () {
    test('比對時會忽略全形/半形空白與大小寫', () async {
      await db.attractionDao.upsertAll([
        buildModel(name: 'Taipei　101 Tower'),
      ]);
      final found = await db.attractionDao.findByName('taipei101tower');
      expect(found, isNotNull);
      expect(found!.id, 1);
    });

    test('找不到對應名稱時回傳 null', () async {
      await db.attractionDao.upsertAll([buildModel()]);
      final found = await db.attractionDao.findByName('不存在的景點');
      expect(found, isNull);
    });
  });

  group('AttractionDao.findById', () {
    test('找不到對應 id 時回傳 null', () async {
      final found = await db.attractionDao.findById(999);
      expect(found, isNull);
    });
  });
}
