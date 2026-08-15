import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/sync/app_sync_service.dart';
import 'package:flutter_travel_audio_guide/core/sync/sync_providers.dart';
import 'package:flutter_travel_audio_guide/core/widgets/list_skeleton.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/models/activity_model.dart';
import 'package:flutter_travel_audio_guide/features/activity/di/activity_providers.dart';
import 'package:flutter_travel_audio_guide/features/activity/presentation/pages/activity_list_page.dart';
import 'package:mocktail/mocktail.dart';

/// Same pattern reused from audio_guide_list_page_test.dart:
/// an in-memory Drift DB and a ProviderScope override for AppSyncService
/// so the controller's _init() can run its real flow without touching
/// real network or persistent storage.
///
/// This test assumes that in lib/features/activity/presentation/controllers/
/// activity_list_controller.dart the finally block in _init() has been
/// corrected from `state.copyWith(isLoadingMore: false)` to
/// `state.copyWith(isSyncing: false)`. Before that fix, isSyncing remains
/// true and the ActivityListPage empty-state branch ("No activities") would
/// never be shown.
class MockAppSyncService extends Mock implements AppSyncService {}

Widget buildTestApp({
  required AppDatabase db,
  AppSyncService? syncService,
  String? initialStatus,
}) {
  final fakeSyncService = syncService ?? _buildInstantSyncService();
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) => db),
      appSyncServiceProvider.overrideWith((ref) => fakeSyncService),
    ],
    child: MaterialApp(home: ActivityListPage(initialStatus: initialStatus)),
  );
}

AppSyncService _buildInstantSyncService() {
  final mock = MockAppSyncService();
  when(mock.syncAllIfNeeded).thenAnswer((_) async {});
  when(() => mock.forceSync(any())).thenAnswer((_) async {});
  return mock;
}

String _formatDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

Future<void> insertActivity(
  AppDatabase db, {
  int id = 1,
  String title = '台北燈節',
  String begin = '2026-07-01',
  String end = '2026-07-31',
}) async {
  await db.activityDao.upsertAll([
    ActivityModel(
      id: id,
      title: title,
      begin: begin,
      end: end,
      posted: begin,
      modified: begin,
      address: '台北市信義區',
      distric: '信義區',
      nlat: '25.03',
      elong: '121.56',
      organizer: '台北市政府',
    ),
  ]);
}

Future<void> disposeWidgetTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // Allow the zero-duration timers created when Drift watch streams are
  // disposed to complete.
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  setUpAll(() {
    registerFallbackValue(SyncTarget.activities);
  });

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('loading 狀態', () {
    testWidgets('明確呼叫 loadInitial() 且尚無資料時顯示 ListSkeleton', (tester) async {
      // The default mock for forceSync is `(_) async {}`, which resolves in
      // the same microtask tick. A plain tester.pump() would let loadInitial()
      // run from start to finally immediately, so the intermediate loading
      // frame cannot be observed. Here we use a Completer to actually block
      // forceSync so the isInitialLoading:true state can be observed.
      final forceSyncCompleter = Completer<void>();
      final mockSync = MockAppSyncService();
      when(mockSync.syncAllIfNeeded).thenAnswer((_) async {});
      when(
        () => mockSync.forceSync(any()),
      ).thenAnswer((_) => forceSyncCompleter.future);
      await tester.pumpWidget(buildTestApp(db: db, syncService: mockSync));
      await tester.pumpAndSettle();
      // The automatic sync triggered at construction (syncAllIfNeeded) has
      // finished, so the UI should be in the empty state.
      expect(find.text('暫無活動資料'), findsOneWidget);
      expect(find.byType(ListSkeleton), findsNothing);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ActivityListPage)),
      );
      final notifier = container.read(activityListControllerProvider.notifier);
      unawaited(notifier.loadInitial());
      await tester.pump();
      expect(find.byType(ListSkeleton), findsOneWidget);
      forceSyncCompleter.complete();
      await tester.pumpAndSettle();
      await disposeWidgetTree(tester);
    });
  });

  group('有活動資料', () {
    testWidgets('DB 有資料時顯示 ActivityTile 列表', (tester) async {
      await insertActivity(db);
      await insertActivity(db, id: 2, title: '花卉展');
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('台北燈節'), findsOneWidget);
      expect(find.text('花卉展'), findsOneWidget);
      await disposeWidgetTree(tester);
    });

    testWidgets('顯示排序/篩選摘要列（預設狀態顯示「預設」）', (tester) async {
      await insertActivity(db);
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('預設'), findsOneWidget);
      await disposeWidgetTree(tester);
    });
  });

  group('空狀態', () {
    testWidgets('sync 完成但無資料時顯示「暫無活動資料」', (tester) async {
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('暫無活動資料'), findsOneWidget);
      await disposeWidgetTree(tester);
    });
  });

  group('AppBar', () {
    testWidgets('顯示「活動展演」標題與排序篩選按鈕', (tester) async {
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('活動展演'), findsOneWidget);
      // In the empty state the summary bar is not shown, so the AppBar only
      // contains one tune icon.
      expect(find.byIcon(Icons.tune), findsOneWidget);
      await disposeWidgetTree(tester);
    });

    testWidgets('有資料時，AppBar 與摘要列各自有一個 tune icon（共 2 個）', (tester) async {
      await insertActivity(db);
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.tune), findsNWidgets(2));
      await disposeWidgetTree(tester);
    });
  });

  group('initialStatus 帶入篩選', () {
    testWidgets('帶入 initialStatus=today 時，只顯示今日活動', (tester) async {
      final now = DateTime.now();
      final today = _formatDate(now);
      final future = _formatDate(now.add(const Duration(days: 20)));
      await insertActivity(db, title: '今日活動A', begin: today, end: today);
      await insertActivity(
        db,
        id: 2,
        title: '未來活動B',
        begin: future,
        end: future,
      );
      await tester.pumpWidget(buildTestApp(db: db, initialStatus: 'today'));
      await tester.pumpAndSettle();
      expect(find.text('今日活動A'), findsOneWidget);
      expect(find.text('未來活動B'), findsNothing);
      // When a non-default filter is active, the summary bar displays the
      // corresponding filter text instead of "Default".
      expect(find.textContaining('今日活動'), findsWidgets);
      await disposeWidgetTree(tester);
    });

    testWidgets('initialStatus 為 null 或無法辨識時維持預設（全部）篩選', (tester) async {
      await insertActivity(db, title: '活動A');
      await tester.pumpWidget(buildTestApp(db: db, initialStatus: 'unknown'));
      await tester.pumpAndSettle();
      expect(find.text('活動A'), findsOneWidget);
      expect(find.text('預設'), findsOneWidget);
      await disposeWidgetTree(tester);
    });
  });

  group('Stream 更新', () {
    testWidgets('初始無資料 → 插入資料後 UI 自動更新', (tester) async {
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('暫無活動資料'), findsOneWidget);
      await insertActivity(db, title: '動態新增活動');
      await tester.pumpAndSettle();
      expect(find.text('動態新增活動'), findsOneWidget);
      expect(find.text('暫無活動資料'), findsNothing);
      await disposeWidgetTree(tester);
    });
  });
}
