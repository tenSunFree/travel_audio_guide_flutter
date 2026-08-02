import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/pages/attraction_detail_page.dart';

Attraction buildAttraction({
  int id = 1,
  String name = '故宮博物院',
  String introduction = '',
  String openTime = '09:00-17:00',
  String address = '台北市士林區',
  String tel = '',
  String ticket = '',
  String remind = '',
  String officialSite = '',
  String facebook = '',
  String modified = '2026-01-01',
  List<AttractionCategory> categories = const [],
  List<AttractionImage> images = const [],
  double? nlat,
  double? elong,
}) {
  return Attraction(
    id: id,
    name: name,
    introduction: introduction,
    openTime: openTime,
    distric: '士林區',
    address: address,
    tel: tel,
    officialSite: officialSite,
    facebook: facebook,
    ticket: ticket,
    remind: remind,
    modified: modified,
    url: '',
    categories: categories,
    targets: const [],
    friendlies: const [],
    images: images,
    nlat: nlat,
    elong: elong,
  );
}

Widget wrap(Attraction attraction) {
  return ProviderScope(
    child: MaterialApp(home: AttractionDetailPage(attraction: attraction)),
  );
}

/// This page uses AppCachedNetworkImage whose default loading placeholder
/// is a continuously animating CircularProgressIndicator. Using pumpAndSettle()
/// can timeout because the animation "never stops". We use a fixed number of
/// pump() calls here instead.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('AttractionDetailPage — 顯示', () {
    testWidgets('AppBar 與內文都顯示景點名稱', (tester) async {
      await tester.pumpWidget(wrap(buildAttraction()));
      await settle(tester);
      expect(find.text('故宮博物院'), findsNWidgets(2)); // AppBar + content title
    });

    testWidgets('沒有圖片時顯示預設的無圖示', (tester) async {
      await tester.pumpWidget(wrap(buildAttraction()));
      await settle(tester);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    testWidgets('有多張圖片時顯示頁碼計數（不等圖片真的載入完成）', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildAttraction(
            images: const [
              AttractionImage(
                src: 'https://example.com/a.png',
                subject: '',
                ext: 'png',
              ),
              AttractionImage(
                src: 'https://example.com/b.png',
                subject: '',
                ext: 'png',
              ),
            ],
          ),
        ),
      );
      await settle(tester);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('只有一張圖片時不顯示頁碼計數', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildAttraction(
            images: const [
              AttractionImage(
                src: 'https://example.com/a.png',
                subject: '',
                ext: 'png',
              ),
            ],
          ),
        ),
      );
      await settle(tester);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.textContaining(' / '), findsNothing);
    });

    testWidgets('有分類時顯示分類 chip', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildAttraction(
            categories: const [AttractionCategory(id: 1, name: '博物館')],
          ),
        ),
      );
      await settle(tester);
      expect(find.text('博物館'), findsOneWidget);
    });

    testWidgets('地址為空時顯示「未提供地址」的 fallback 文字', (tester) async {
      await tester.pumpWidget(wrap(buildAttraction(address: '')));
      await settle(tester);
      expect(find.text('未提供地址'), findsOneWidget);
    });

    testWidgets('開放時間/電話/票價/提醒事項都有資料時，各自獨立顯示', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildAttraction(
            tel: '02-1234-5678',
            ticket: '免費參觀',
            remind: '每週一休館',
          ),
        ),
      );
      await settle(tester);
      expect(find.text('09:00-17:00'), findsOneWidget);
      expect(find.text('02-1234-5678'), findsOneWidget);
      expect(find.text('免費參觀'), findsOneWidget);
      expect(find.text('每週一休館'), findsOneWidget);
    });

    testWidgets('開放時間/電話/票價/提醒事項都是空字串時，都不顯示', (tester) async {
      await tester.pumpWidget(
        wrap(buildAttraction(openTime: '')),
      );
      await settle(tester);
      expect(find.byIcon(Icons.access_time), findsNothing);
      expect(find.byIcon(Icons.phone_outlined), findsNothing);
      expect(find.byIcon(Icons.confirmation_number_outlined), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('景點介紹為空時顯示「目前沒有景點介紹」', (tester) async {
      await tester.pumpWidget(wrap(buildAttraction()));
      await settle(tester);
      expect(find.text('目前沒有景點介紹'), findsOneWidget);
    });

    testWidgets('景點介紹有內容時顯示實際內容', (tester) async {
      await tester.pumpWidget(
        wrap(buildAttraction(introduction: '這是一段景點介紹文字')),
      );
      await settle(tester);
      expect(find.text('這是一段景點介紹文字'), findsOneWidget);
      expect(find.text('目前沒有景點介紹'), findsNothing);
    });

    testWidgets('官網與 Facebook 都沒有時，不顯示外部連結區塊', (tester) async {
      await tester.pumpWidget(
        wrap(buildAttraction()),
      );
      await settle(tester);
      expect(find.text('官方網站'), findsNothing);
      expect(find.text('Facebook'), findsNothing);
    });

    testWidgets('只有官網時只顯示官方網站連結列', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildAttraction(officialSite: 'https://example.com'),
        ),
      );
      await settle(tester);
      expect(find.text('官方網站'), findsOneWidget);
      expect(find.text('Facebook'), findsNothing);
    });

    testWidgets('官網跟 Facebook 都有時，兩個連結列都顯示', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildAttraction(
            officialSite: 'https://example.com',
            facebook: 'https://facebook.com/example',
          ),
        ),
      );
      await settle(tester);
      expect(find.text('官方網站'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
    });

    testWidgets('顯示最後更新日期（只取空白前的日期部分）', (tester) async {
      await tester.pumpWidget(
        wrap(buildAttraction(modified: '2026-05-01 10:00:00')),
      );
      await settle(tester);
      expect(find.text('最後更新：2026-05-01'), findsOneWidget);
    });

    testWidgets('modified 為空字串時不顯示最後更新列', (tester) async {
      await tester.pumpWidget(wrap(buildAttraction(modified: '')));
      await settle(tester);
      expect(find.textContaining('最後更新'), findsNothing);
    });

    testWidgets('顯示行動按鈕：設定提醒/行事曆/分享景點/開始導航', (tester) async {
      await tester.pumpWidget(wrap(buildAttraction()));
      await settle(tester);
      expect(find.text('設定提醒'), findsOneWidget);
      expect(find.text('行事曆'), findsOneWidget);
      expect(find.text('分享景點'), findsOneWidget);
      expect(find.text('開始導航'), findsOneWidget);
    });
  });
}
