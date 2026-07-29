import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_travel_audio_guide/core/widgets/route_error_page.dart';

void main() {
  testWidgets('displays error title and message', (tester) async {
    final router = GoRouter(
      initialLocation: '/error',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('首頁')),
        ),
        GoRoute(
          path: '/error',
          builder: (_, _) => const RouteErrorPage(message: '找不到資料'),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('資料錯誤'), findsOneWidget);
    expect(find.text('找不到資料'), findsOneWidget);
    await tester.tap(find.text('回首頁'));
    await tester.pumpAndSettle();
    expect(find.text('首頁'), findsOneWidget);
  });
}
