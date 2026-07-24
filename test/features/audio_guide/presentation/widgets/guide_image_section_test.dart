import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/widgets/guide_image_section.dart';

Attraction _buildAttraction({List<AttractionImage> images = const []}) {
  return Attraction(
    id: 1,
    name: '測試景點',
    introduction: '',
    openTime: '',
    distric: '',
    address: '',
    tel: '',
    officialSite: '',
    facebook: '',
    ticket: '',
    remind: '',
    modified: '',
    url: '',
    categories: const [],
    targets: const [],
    friendlies: const [],
    images: images,
  );
}

void main() {
  group('GuideImageSection', () {
    testWidgets('attraction 為 null 時顯示 placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GuideImageSection(attraction: null)),
        ),
      );
      expect(find.byIcon(Icons.headphones_outlined), findsOneWidget);
      expect(find.text('語音導覽'), findsOneWidget);
    });

    testWidgets('images 為空時顯示 placeholder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuideImageSection(attraction: _buildAttraction()),
          ),
        ),
      );
      expect(find.text('語音導覽'), findsOneWidget);
    });

    testWidgets('單張圖片時不顯示頁碼指示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuideImageSection(
              attraction: _buildAttraction(
                images: const [
                  AttractionImage(
                    src: 'https://example.com/1.jpg',
                    subject: '',
                    ext: '',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('/'), findsNothing);
    });

    testWidgets('多張圖片顯示頁碼，滑動後頁碼更新', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuideImageSection(
              attraction: _buildAttraction(
                images: const [
                  AttractionImage(
                    src: 'https://example.com/1.jpg',
                    subject: '',
                    ext: '',
                  ),
                  AttractionImage(
                    src: 'https://example.com/2.jpg',
                    subject: '',
                    ext: '',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('1 / 2'), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      // Advance the PageView's scroll animation by pumping a fixed number of frames.
      // Do not use pumpAndSettle (image loading background animations/retries can prevent it from ever settling).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2 / 2'), findsOneWidget);
    });
  });
}
