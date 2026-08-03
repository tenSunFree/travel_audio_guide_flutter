import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/data/services/step_tracking_service_impl.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/di/step_tracking_providers.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/presentation/controllers/step_tracking_controller.dart';

/// Flush the microtask queue so the chained `await`s inside
/// `StepTrackingController._init()` (checkAvailability → hasPermissions →
/// requestPermissions → hasActivityRecognitionPermission →
/// requestActivityRecognitionPermission) fully resolve before we tear down
/// the provider. Without this, disposal races with `_init()` and hits
/// `Bad state: Tried to use StepTrackingController after dispose was called.`
Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('desktop test environment 回傳 NoOpStepTrackingService', () {
    if (Platform.isAndroid) return;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(stepTrackingServiceProvider);
    expect(service, isA<NoOpStepTrackingService>());
  });

  test(
    'stepTrackingControllerProvider 組裝出綁定 stepTrackingServiceProvider 的 controller',
    () async {
      if (Platform.isAndroid) return;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Providers with `.autoDispose` are immediately disposed when they have no listeners.
      // Keep a live subscription with `container.listen` so the controller remains
      // alive for the duration of the test.
      final sub = container.listen(
        stepTrackingControllerProvider.notifier,
        (_, _) {},
      );
      addTearDown(sub.close);
      final controller = sub.read();
      expect(controller, isA<StepTrackingController>());
      // Allow the await chain inside `_init()` to complete before tearDown disposes
      // the controller.
      await _flush();
    },
  );
}
