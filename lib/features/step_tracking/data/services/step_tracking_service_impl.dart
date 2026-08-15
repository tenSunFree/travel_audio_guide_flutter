import 'package:flutter_travel_audio_guide/features/step_tracking/data/health_connect_api.g.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/domain/entities/exercise_summary_data.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/domain/services/step_tracking_service.dart';

class StepTrackingServiceImpl implements StepTrackingService {
  StepTrackingServiceImpl() : _api = HealthConnectHostApi();

  final HealthConnectHostApi _api;

  @override
  Future<bool> checkAvailability() => _api.checkAvailability();

  @override
  Future<bool> requestPermissions() => _api.requestPermissions();

  @override
  Future<bool> hasPermissions() => _api.hasPermissions();

  @override
  Future<int> getStepsBetween(DateTime start, DateTime end) =>
      _api.getStepsBetween(
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      );

  @override
  Future<double> getDistanceBetween(DateTime start, DateTime end) async {
    final cm = await _api.getDistanceBetween(
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    );
    return cm / 100.0;
  }

  @override
  Future<void> writeExerciseSession(ExerciseSummaryData data) async {
    await _api.writeExerciseSession(
      data.guideName,
      data.startTime.millisecondsSinceEpoch,
      data.endTime.millisecondsSinceEpoch,
      data.steps,
      (data.distanceMeters * 100).round(),
    );
  }

  @override
  Future<bool> isStepSensorAvailable() => _api.isStepSensorAvailable();

  @override
  Future<void> startStepSensorTracking() => _api.startStepSensorTracking();

  @override
  Future<void> pauseStepSensorTracking() => _api.pauseStepSensorTracking();

  @override
  Future<int> stopStepSensorTracking() => _api.stopStepSensorTracking();

  @override
  Future<int> getCurrentSensorSteps() => _api.getCurrentSensorSteps();

  @override
  Future<bool> hasActivityRecognitionPermission() =>
      _api.hasActivityRecognitionPermission();

  @override
  Future<bool> requestActivityRecognitionPermission() =>
      _api.requestActivityRecognitionPermission();

  @override
  Future<void> resumeStepSensorTracking() => _api.resumeStepSensorTracking();
}

/// Returned on non-Android platforms so the rest of the app compiles unchanged.
class NoOpStepTrackingService implements StepTrackingService {
  const NoOpStepTrackingService();

  @override
  Future<bool> checkAvailability() async => false;

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<bool> hasPermissions() async => false;

  @override
  Future<int> getStepsBetween(DateTime start, DateTime end) async => 0;

  @override
  Future<double> getDistanceBetween(DateTime start, DateTime end) async => 0.0;

  @override
  Future<void> writeExerciseSession(ExerciseSummaryData data) async {}

  @override
  Future<bool> isStepSensorAvailable() async => false;

  @override
  Future<void> startStepSensorTracking() async {}

  @override
  Future<void> pauseStepSensorTracking() async {}

  @override
  Future<int> stopStepSensorTracking() async => 0;

  @override
  Future<int> getCurrentSensorSteps() async => 0;

  @override
  Future<bool> hasActivityRecognitionPermission() async => false;

  @override
  Future<bool> requestActivityRecognitionPermission() async => false;

  @override
  Future<void> resumeStepSensorTracking() async {}
}
