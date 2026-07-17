import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity.dart';
import 'package:flutter_travel_audio_guide/features/activity/presentation/widgets/activity_link_row.dart';

void main() {
  testWidgets('ActivityLinkRow renders subject as title and responds to tap', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityLinkRow(
            link: const ActivityLink(
              subject: '官方網站',
              src: 'https://example.com',
            ),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('官方網站'), findsOneWidget);
    expect(find.byIcon(Icons.link), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });

  testWidgets('ActivityLinkRow falls back to src when subject is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityLinkRow(
            link: const ActivityLink(
              subject: '',
              src: 'https://example.com/page',
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('https://example.com/page'), findsOneWidget);
  });
}
