import 'package:flutter_travel_audio_guide/features/step_tracking/domain/entities/exercise_summary_data.dart';

abstract class StepTrackingService {
  Future<bool> checkAvailability();

  Future<bool> requestPermissions();

  Future<bool> hasPermissions();

  Future<int> getStepsBetween(DateTime start, DateTime end);

  Future<double> getDistanceBetween(DateTime start, DateTime end);

  Future<void> writeExerciseSession(ExerciseSummaryData data);

  Future<bool> isStepSensorAvailable();

  Future<void> startStepSensorTracking();

  Future<void> pauseStepSensorTracking();

  Future<int> stopStepSensorTracking();

  Future<int> getCurrentSensorSteps();

  Future<bool> hasActivityRecognitionPermission();

  Future<bool> requestActivityRecognitionPermission();

  Future<void> resumeStepSensorTracking();
}
