import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_travel_audio_guide/core/nearby/location_controller.dart';
import 'package:flutter_travel_audio_guide/core/nearby/nearby_models.dart';

class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}

void main() {
  late MockGeolocatorPlatform mockPlatform;
  late LocationController controller;

  setUp(() {
    mockPlatform = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockPlatform;
    controller = LocationController();
  });

  test(
    'when location service is disabled, state becomes serviceDisabled',
    () async {
      when(
        () => mockPlatform.isLocationServiceEnabled(),
      ).thenAnswer((_) async => false);
      final point = await controller.getCurrentLocation();
      expect(point, isNull);
      expect(
        controller.state.permissionState,
        NearbyPermissionState.serviceDisabled,
      );
    },
  );

  test('when permission is denied, state becomes denied', () async {
    when(
      () => mockPlatform.isLocationServiceEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => mockPlatform.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.denied);
    when(
      () => mockPlatform.requestPermission(),
    ).thenAnswer((_) async => LocationPermission.denied);
    final point = await controller.getCurrentLocation();
    expect(point, isNull);
    expect(controller.state.permissionState, NearbyPermissionState.denied);
  });

  test(
    'when permission is permanently denied, state becomes deniedForever',
    () async {
      when(
        () => mockPlatform.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => mockPlatform.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.deniedForever);
      final point = await controller.getCurrentLocation();
      expect(point, isNull);
      expect(
        controller.state.permissionState,
        NearbyPermissionState.deniedForever,
      );
    },
  );

  test(
    'on successful location fetch, returns coordinates and updates cache',
    () async {
      when(
        () => mockPlatform.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => mockPlatform.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);
      when(
        () => mockPlatform.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer(
        (_) async => Position(
          latitude: 25.03,
          longitude: 121.56,
          timestamp: DateTime.now(),
          accuracy: 5,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
      final point = await controller.getCurrentLocation();
      expect(point, isNotNull);
      expect(point!.latitude, 25.03);
      expect(controller.state.permissionState, NearbyPermissionState.granted);
      expect(controller.state.hasValidLocation, true);
    },
  );

  test(
    'when cache is fresh, returns cached location without re-requesting',
    () async {
      when(
        () => mockPlatform.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => mockPlatform.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);
      when(
        () => mockPlatform.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer(
        (_) async => Position(
          latitude: 1,
          longitude: 1,
          timestamp: DateTime.now(),
          accuracy: 5,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
      // First call: actually triggers location fetch
      await controller.getCurrentLocation();
      verify(
        () => mockPlatform.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).called(1);
      // Second call: hits cache, should not call getCurrentPosition again
      await controller.getCurrentLocation();
      verifyNever(
        () => mockPlatform.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      );
    },
  );
}
