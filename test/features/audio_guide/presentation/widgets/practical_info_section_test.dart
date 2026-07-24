import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/widgets/practical_info_section.dart';

Attraction _buildAttraction({
  String address = '',
  String openTime = '',
  String tel = '',
  String ticket = '',
  String remind = '',
}) {
  return Attraction(
    id: 1,
    name: '測試景點',
    introduction: '',
    openTime: openTime,
    distric: '',
    address: address,
    tel: tel,
    officialSite: '',
    facebook: '',
    ticket: ticket,
    remind: remind,
    modified: '',
    url: '',
    categories: const [],
    targets: const [],
    friendlies: const [],
    images: const [],
  );
}

void main() {
  group('PracticalInfoSection', () {
    testWidgets('attraction 為 null 時顯示找不到資訊', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PracticalInfoSection(attraction: null)),
        ),
      );
      expect(find.text('未找到對應景點資訊'), findsOneWidget);
    });

    testWidgets('欄位皆為空時，不顯示任何 InfoRow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PracticalInfoSection(attraction: _buildAttraction()),
          ),
        ),
      );
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
      expect(find.byIcon(Icons.access_time_outlined), findsNothing);
    });

    testWidgets('欄位有值時顯示對應 InfoRow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PracticalInfoSection(
              attraction: _buildAttraction(
                address: '台北市信義區',
                openTime: '09:00-18:00',
                tel: '02-12345678',
                ticket: '全票 100 元',
                remind: '雨天不開放',
              ),
            ),
          ),
        ),
      );
      expect(find.text('台北市信義區'), findsOneWidget);
      expect(find.text('09:00-18:00'), findsOneWidget);
      expect(find.text('02-12345678'), findsOneWidget);
      expect(find.text('全票 100 元'), findsOneWidget);
      expect(find.text('雨天不開放'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
    });
  });
}
