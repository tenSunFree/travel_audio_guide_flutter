import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/activity/presentation/pages/activity_detail_page.dart';
import '../../../../test_helpers/activity_fixtures.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity.dart';

Widget buildSubject(Activity activity) {
  return ProviderScope(
    child: MaterialApp(home: ActivityDetailPage(activity: activity)),
  );
}

void main() {
  testWidgets('顯示活動標題、展期、主辦單位與地點', (tester) async {
    final activity = buildTestActivity();
    await tester.pumpWidget(buildSubject(activity));
    await tester
        .pump(); // allow the AnalyticsService call in initState to complete one cycle
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('台北燈節'), findsOneWidget);
    expect(find.text('2026/08/01 ～ 2026/08/10'), findsOneWidget);
    expect(find.text('臺北市政府'), findsOneWidget);
    expect(find.text('台北市中正區'), findsOneWidget);
    expect(find.text('地點'), findsOneWidget);
  });

  testWidgets('地址為空時不顯示地點列，但主辦單位仍會顯示', (tester) async {
    final activity = buildTestActivity(address: '', organizer: '文化局');
    await tester.pumpWidget(buildSubject(activity));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('地點'), findsNothing);
    expect(find.text('主辦'), findsOneWidget);
    expect(find.text('文化局'), findsOneWidget);
  });

  testWidgets('點擊收藏會切換圖示與提示文字', (tester) async {
    final activity = buildTestActivity();
    await tester.pumpWidget(buildSubject(activity));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text('已加入收藏'), findsOneWidget);
  });

  testWidgets('票價與電話存在時會顯示對應資訊列', (tester) async {
    final activity = buildTestActivity(tel: '0223456789', ticket: 'NT\$100');
    await tester.pumpWidget(buildSubject(activity));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('電話'), findsOneWidget);
    expect(find.text('0223456789'), findsOneWidget);
    expect(find.text('票價'), findsOneWidget);
    expect(find.text('NT\$100'), findsOneWidget);
  });
}
