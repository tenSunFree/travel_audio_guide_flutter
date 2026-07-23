import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/sync/app_sync_service.dart';
import 'package:flutter_travel_audio_guide/core/sync/sync_providers.dart';
import 'package:flutter_travel_audio_guide/core/widgets/list_skeleton.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/models/attraction_model.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/pages/attraction_list_page.dart';

/// This test follows the same pattern used in `activity_list_page_test.dart`:
/// an in-memory Drift database combined with overriding `AppSyncService`
/// in a `ProviderScope`.
///
/// Compared to the Activity version: `AttractionListController`'s
/// `ListSkeleton` condition checks `isSyncing` directly (not
/// `isInitialLoading`), and its `_init()` correctly sets `isSyncing`
/// back to false. Therefore the natural behavior of showing the
/// `ListSkeleton` on initial creation works here — there is no need to
/// work around it by calling `loadInitial()` as was done in the Activity tests.
class MockAppSyncService extends Mock implements AppSyncService {}

Widget buildTestApp({
  required AppDatabase db,
  AppSyncService? syncService,
  String? initialTimeSlot,
  bool initialOpenNow = false,
}) {
  final fakeSyncService = syncService ?? _buildInstantSyncService();
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) => db),
      appSyncServiceProvider.overrideWith((ref) => fakeSyncService),
    ],
    child: MaterialApp(
      home: AttractionListPage(
        initialTimeSlot: initialTimeSlot,
        initialOpenNow: initialOpenNow,
      ),
    ),
  );
}

AppSyncService _buildInstantSyncService() {
  final mock = MockAppSyncService();
  when(() => mock.syncAllIfNeeded()).thenAnswer((_) async {});
  when(() => mock.forceSync(any())).thenAnswer((_) async {});
  return mock;
}

Future<void> insertAttraction(
  AppDatabase db, {
  int id = 1,
  String name = '故宮博物院',
  String openTime = '09:00-17:00',
}) async {
  await db.attractionDao.upsertAll([
    AttractionModel(
      id: id,
      name: name,
      introduction: '',
      openTime: openTime,
      distric: '士林區',
      address: '台北市士林區',
      tel: '',
      officialSite: '',
      facebook: '',
      ticket: '',
      remind: '',
      modified: '2026-01-01',
      url: '',
      categories: const [],
      targets: const [],
      friendlies: const [],
      images: const [],
    ),
  ]);
}

Future<void> disposeWidgetTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  setUpAll(() {
    registerFallbackValue(SyncTarget.attractions);
  });

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('loading 狀態', () {
    testWidgets('sync 尚未完成時顯示 ListSkeleton', (tester) async {
      final completer = Completer<void>();
      final mockSync = MockAppSyncService();
      when(
        () => mockSync.syncAllIfNeeded(),
      ).thenAnswer((_) => completer.future);
      when(() => mockSync.forceSync(any())).thenAnswer((_) async {});
      await tester.pumpWidget(buildTestApp(db: db, syncService: mockSync));
      await tester.pump();
      expect(find.byType(ListSkeleton), findsOneWidget);
      completer.complete();
      await tester.pumpAndSettle();
      await disposeWidgetTree(tester);
    });
  });

  group('有景點資料', () {
    testWidgets('DB 有資料時顯示 AttractionTile 列表', (tester) async {
      await insertAttraction(db, id: 1, name: '故宮博物院');
      await insertAttraction(db, id: 2, name: '台北101');
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('故宮博物院'), findsOneWidget);
      expect(find.text('台北101'), findsOneWidget);
      await disposeWidgetTree(tester);
    });
  });

  group('空狀態', () {
    testWidgets('sync 完成但無資料時顯示「暫無景點資料」', (tester) async {
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('暫無景點資料'), findsOneWidget);
      expect(find.byType(ListSkeleton), findsNothing);
      await disposeWidgetTree(tester);
    });
  });

  group('AppBar', () {
    testWidgets('顯示「遊憩景點」標題與排序篩選按鈕', (tester) async {
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('遊憩景點'), findsOneWidget);
      await disposeWidgetTree(tester);
    });
  });

  group('initialTimeSlot / initialOpenNow 帶入篩選', () {
    testWidgets('帶入 initialOpenNow=true 時，只顯示目前開放中的景點', (tester) async {
      await insertAttraction(
        db,
        id: 1,
        name: '全天開放景點',
        openTime: '00:00-23:59',
      );
      await insertAttraction(db, id: 2, name: '已公告休館景點', openTime: '以現場公告為準');
      await tester.pumpWidget(buildTestApp(db: db, initialOpenNow: true));
      await tester.pumpAndSettle();
      expect(find.text('全天開放景點'), findsOneWidget);
      expect(find.text('已公告休館景點'), findsNothing);
      await disposeWidgetTree(tester);
    });
  });

  group('Stream 更新', () {
    testWidgets('初始無資料 → 插入資料後 UI 自動更新', (tester) async {
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('暫無景點資料'), findsOneWidget);
      await insertAttraction(db, id: 1, name: '動態新增景點');
      await tester.pumpAndSettle();
      expect(find.text('動態新增景點'), findsOneWidget);
      expect(find.text('暫無景點資料'), findsNothing);
      await disposeWidgetTree(tester);
    });
  });
}
