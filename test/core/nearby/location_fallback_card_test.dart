import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/nearby/location_fallback_card.dart';
import 'package:flutter_travel_audio_guide/core/nearby/nearby_models.dart';

void main() {
  Widget buildSubject(
    NearbyPermissionState state, {
    bool isLoading = false,
    VoidCallback? onRequestLocation,
    VoidCallback? onOpenSettings,
    VoidCallback? onOpenLocationService,
    VoidCallback? onBrowseAll,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: LocationFallbackCard(
          permissionState: state,
          isLoading: isLoading,
          onRequestLocation: onRequestLocation ?? () {},
          onOpenSettings: onOpenSettings ?? () {},
          onOpenLocationService: onOpenLocationService ?? () {},
          onBrowseAll: onBrowseAll ?? () {},
        ),
      ),
    );
  }

  testWidgets('granted state shows no content', (tester) async {
    await tester.pumpWidget(buildSubject(NearbyPermissionState.granted));
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('initial state shows prompt to enable location', (tester) async {
    await tester.pumpWidget(buildSubject(NearbyPermissionState.initial));
    expect(find.text('開啟附近推薦'), findsOneWidget);
    expect(find.text('開啟定位'), findsOneWidget);
  });

  testWidgets('initial + isLoading shows spinner on button and disables it', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(NearbyPermissionState.initial, isLoading: true),
    );
    // When isLoading, primaryLabel text is hidden and only a spinner is shown
    expect(find.text('定位中...'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Button onPressed is null (disabled) when isLoading
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'denied state shows re-enable location and browse all attractions',
    (tester) async {
      await tester.pumpWidget(buildSubject(NearbyPermissionState.denied));
      expect(find.text('尚未開啟定位'), findsOneWidget);
      expect(find.text('重新開啟定位'), findsOneWidget);
      expect(find.text('瀏覽全部景點'), findsOneWidget);
    },
  );

  testWidgets(
    'deniedForever state shows open settings and tapping triggers callback',
    (tester) async {
      var called = false;
      await tester.pumpWidget(
        buildSubject(
          NearbyPermissionState.deniedForever,
          onOpenSettings: () => called = true,
        ),
      );
      expect(find.text('定位權限已關閉'), findsOneWidget);
      expect(find.text('前往設定'), findsOneWidget);
      await tester.tap(find.text('前往設定'));
      expect(called, isTrue);
    },
  );

  testWidgets(
    'serviceDisabled state shows open location service and tapping triggers callback',
    (tester) async {
      var called = false;
      await tester.pumpWidget(
        buildSubject(
          NearbyPermissionState.serviceDisabled,
          onOpenLocationService: () => called = true,
        ),
      );
      expect(find.text('定位服務未開啟'), findsOneWidget);
      expect(find.text('開啟定位服務'), findsOneWidget);
      expect(find.text('稍後再說'), findsOneWidget);
      await tester.tap(find.text('開啟定位服務'));
      expect(called, isTrue);
    },
  );

  testWidgets('failure state shows retry option', (tester) async {
    await tester.pumpWidget(buildSubject(NearbyPermissionState.failure));
    expect(find.text('無法取得位置'), findsOneWidget);
    expect(find.text('重新嘗試'), findsOneWidget);
  });

  testWidgets(
    'tapping primary button in initial state triggers corresponding callback',
    (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildSubject(
          NearbyPermissionState.initial,
          onRequestLocation: () => tapped = true,
        ),
      );
      await tester.tap(find.text('開啟定位'));
      await tester.pump();
      expect(tapped, true);
    },
  );
}
