import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/models/activity_model.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ActivityModel buildModel({
    int id = 1,
    String title = '台北燈節',
    String begin = '2026-01-01',
    String modified = '2026-01-01',
    List<ActivityLinkModel> links = const [],
  }) {
    return ActivityModel(
      id: id,
      title: title,
      description: '活動描述',
      begin: begin,
      end: '2026-01-10',
      posted: '2026-01-01',
      modified: modified,
      url: '',
      address: '台北市信義區',
      distric: '信義區',
      nlat: '25.03',
      elong: '121.56',
      organizer: '台北市政府',
      coRganizer: '',
      contact: '',
      tel: '',
      ticket: '免費',
      traffic: '',
      parking: '',
      links: links,
    );
  }

  group('ActivityDao.upsertAll / getAll', () {
    test('寫入後可以完整讀回基本欄位', () async {
      await db.activityDao.upsertAll([buildModel(id: 1, title: '台北燈節')]);
      final all = await db.activityDao.getAll();
      expect(all, hasLength(1));
      expect(all.single.title, '台北燈節');
      expect(all.single.address, '台北市信義區');
    });

    test('links 會正確序列化並可還原', () async {
      await db.activityDao.upsertAll([
        buildModel(
          id: 1,
          links: const [
            ActivityLinkModel(src: 'https://example.com', subject: '官網'),
          ],
        ),
      ]);
      final entity = await db.activityDao.findById(1);
      expect(entity, isNotNull);
      expect(entity!.links.single.src, 'https://example.com');
      expect(entity.links.single.subject, '官網');
    });

    test('相同 id 再次 upsert 會更新既有資料，而不是新增一筆', () async {
      await db.activityDao.upsertAll([
        buildModel(id: 1, title: '舊標題', modified: '2026-01-01'),
      ]);
      await db.activityDao.upsertAll([
        buildModel(id: 1, title: '新標題', modified: '2026-02-01'),
      ]);
      final all = await db.activityDao.getAll();
      expect(all, hasLength(1));
      expect(all.single.title, '新標題');
    });
  });

  group('ActivityDao.watchAll', () {
    test('依 begin 字串降冪排序（最新的活動在前）', () async {
      await db.activityDao.upsertAll([
        buildModel(id: 1, title: '較早的活動', begin: '2026-01-01'),
        buildModel(id: 2, title: '較晚的活動', begin: '2026-06-01'),
      ]);
      final list = await db.activityDao.watchAll().first;
      expect(list.map((a) => a.title), ['較晚的活動', '較早的活動']);
    });
  });

  group('ActivityDao.findById', () {
    test('找不到對應 id 時回傳 null', () async {
      final found = await db.activityDao.findById(999);
      expect(found, isNull);
    });
  });
}
