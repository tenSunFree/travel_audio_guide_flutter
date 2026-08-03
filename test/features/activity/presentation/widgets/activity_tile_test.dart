import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity.dart';
import 'package:flutter_travel_audio_guide/features/activity/presentation/widgets/activity_tile.dart';

Activity buildActivity({
  int id = 1,
  String title = '台北藝術展',
  String description = '<p>這是一場精彩的藝術展覽</p>',
  String begin = '2026-07-20',
  String end = '2026-07-30',
  String organizer = '台北市文化局',
  String nlat = '25.0330',
  String elong = '121.5654',
}) {
  return Activity(
    id: id,
    title: title,
    description: description,
    begin: begin,
    end: end,
    posted: '',
    modified: '',
    url: '',
    address: '台北市信義區',
    distric: '信義區',
    nlat: nlat,
    elong: elong,
    organizer: organizer,
    coRganizer: '',
    contact: '',
    tel: '',
    ticket: '',
    traffic: '',
    parking: '',
    links: const [],
  );
}

Widget wrap(
  Activity activity, {
  VoidCallback? onTap,
  double? userLat,
  double? userLng,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ActivityTile(
        activity: activity,
        onTap: onTap ?? () {},
        userLat: userLat,
        userLng: userLng,
      ),
    ),
  );
}

void main() {
  group('ActivityTile — 顯示', () {
    testWidgets('顯示活動標題', (tester) async {
      await tester.pumpWidget(wrap(buildActivity(title: '故宮特展')));
      expect(find.text('故宮特展'), findsOneWidget);
    });

    testWidgets('日期格式化為 yyyy/MM/dd', (tester) async {
      await tester.pumpWidget(
        wrap(buildActivity()),
      );
      expect(find.textContaining('2026/07/20'), findsOneWidget);
      expect(find.textContaining('2026/07/30'), findsOneWidget);
    });

    testWidgets('顯示主辦單位', (tester) async {
      await tester.pumpWidget(wrap(buildActivity()));
      expect(find.text('台北市文化局'), findsOneWidget);
    });

    testWidgets('HTML 描述轉換為純文字', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildActivity(description: '<p>精彩展覽</p><br><strong>歡迎參觀</strong>'),
        ),
      );
      expect(find.textContaining('精彩展覽'), findsOneWidget);
      expect(find.textContaining('歡迎參觀'), findsOneWidget);
    });

    testWidgets('HTML entity 正確轉換（&amp; 與 &mdash;）', (tester) async {
      await tester.pumpWidget(
        wrap(buildActivity(description: 'A &amp; B &mdash; Test')),
      );
      expect(find.textContaining('A & B — Test'), findsOneWidget);
    });

    testWidgets('沒有主辦單位時不會拋出例外', (tester) async {
      await tester.pumpWidget(wrap(buildActivity(organizer: '')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('有使用者座標且景點座標有效時顯示距離', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildActivity(),
          userLat: 25.0331,
          userLng: 121.5655,
        ),
      );
      expect(find.textContaining('距你'), findsOneWidget);
    });

    testWidgets('座標無效時不顯示距離', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildActivity(nlat: '', elong: ''),
          userLat: 25.0331,
          userLng: 121.5655,
        ),
      );
      expect(find.textContaining('距你'), findsNothing);
    });
  });

  group('ActivityTile — 互動', () {
    testWidgets('點擊 Tile 觸發 onTap', (tester) async {
      var called = false;
      await tester.pumpWidget(
        wrap(buildActivity(), onTap: () => called = true),
      );
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(called, isTrue);
    });
  });

  group('ActivityTile — Layout 安全性', () {
    testWidgets('超長標題不會拋出 overflow 例外', (tester) async {
      await tester.pumpWidget(wrap(buildActivity(title: '非常長的活動標題' * 30)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('超長描述不會拋出 overflow 例外', (tester) async {
      await tester.pumpWidget(
        wrap(buildActivity(description: '非常長的活動介紹內容' * 100)),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
