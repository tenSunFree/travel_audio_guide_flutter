import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/data/services/step_tracking_service_impl.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/di/step_tracking_providers.dart';

void main() {
  test('desktop test environment 回傳 NoOpStepTrackingService', () {
    if (Platform.isAndroid) return;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(stepTrackingServiceProvider);
    expect(service, isA<NoOpStepTrackingService>());
  });
}
