import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/router/loaders/activity_detail_loader.dart';
import 'package:flutter_travel_audio_guide/core/router/loaders/attraction_detail_loader.dart';
import 'package:flutter_travel_audio_guide/core/router/loaders/audio_guide_detail_loader.dart';

void main() {
  testWidgets('ActivityDetailLoader：idText 非數字時顯示錯誤頁', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ActivityDetailLoader(idText: 'abc', initialActivity: null),
        ),
      ),
    );
    expect(find.text('活動 ID 格式錯誤'), findsOneWidget);
  });

  testWidgets('ActivityDetailLoader：idText 為空字串時顯示錯誤頁', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ActivityDetailLoader(idText: '', initialActivity: null),
        ),
      ),
    );
    expect(find.text('活動 ID 格式錯誤'), findsOneWidget);
  });

  testWidgets('AttractionDetailLoader：idText 為 null 時顯示錯誤頁', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AttractionDetailLoader(idText: null, initialAttraction: null),
        ),
      ),
    );
    expect(find.text('景點 ID 格式錯誤'), findsOneWidget);
  });

  testWidgets('AudioGuideDetailLoader：idText 非數字時顯示錯誤頁', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AudioGuideDetailLoader(idText: 'xx', initialGuide: null),
        ),
      ),
    );
    expect(find.text('語音導覽 ID 格式錯誤'), findsOneWidget);
  });
}
