import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/domain/entities/exercise_summary_data.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/domain/services/step_tracking_service.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/presentation/controllers/step_tracking_controller.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/presentation/enums/step_tracking_source.dart';

class MockStepTrackingService extends Mock implements StepTrackingService {}

class _FakeExerciseSummaryData extends Fake implements ExerciseSummaryData {}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late MockStepTrackingService service;

  setUpAll(() {
    registerFallbackValue(_FakeExerciseSummaryData());
  });

  setUp(() {
    service = MockStepTrackingService();
  });

  group('StepTrackingState.isReady', () {
    test('source=sensor 時，就緒與否只看 isAvailable + hasSensorPermission', () {
      const ready = StepTrackingState(
        isAvailable: true,
        hasSensorPermission: true,
        hasHealthConnectPermission: false,
      );
      expect(ready.isReady, isTrue);
      const notReady = StepTrackingState(
        isAvailable: true,
        hasSensorPermission: false,
      );
      expect(notReady.isReady, isFalse);
    });

    test(
      'source=healthConnect 時，就緒與否只看 isAvailable + hasHealthConnectPermission',
      () {
        const ready = StepTrackingState(
          source: StepTrackingSource.healthConnect,
          isAvailable: true,
          hasHealthConnectPermission: true,
          hasSensorPermission: false,
        );
        expect(ready.isReady, isTrue);
        const notReady = StepTrackingState(
          source: StepTrackingSource.healthConnect,
          isAvailable: true,
          hasHealthConnectPermission: false,
          hasSensorPermission: true,
        );
        expect(notReady.isReady, isFalse);
      },
    );
  });

  Future<StepTrackingController> buildReadyController({
    bool available = true,
    bool hasHcPermission = true,
    bool hasSensorPermission = true,
  }) async {
    when(() => service.checkAvailability()).thenAnswer((_) async => available);
    when(
      () => service.hasPermissions(),
    ).thenAnswer((_) async => hasHcPermission);
    when(
      () => service.requestPermissions(),
    ).thenAnswer((_) async => hasHcPermission);
    when(
      () => service.hasActivityRecognitionPermission(),
    ).thenAnswer((_) async => hasSensorPermission);
    when(
      () => service.requestActivityRecognitionPermission(),
    ).thenAnswer((_) async => hasSensorPermission);
    final controller = StepTrackingController(service);
    await _flush();
    return controller;
  }

  group('StepTrackingController._init', () {
    test('已經授權時不會再嘗試申請權限，直接反映目前狀態', () async {
      final controller = await buildReadyController();
      expect(controller.state.isAvailable, isTrue);
      expect(controller.state.hasHealthConnectPermission, isTrue);
      expect(controller.state.hasSensorPermission, isTrue);
      verifyNever(() => service.requestPermissions());
      verifyNever(() => service.requestActivityRecognitionPermission());
      controller.dispose();
    });

    test('尚未授權時會嘗試申請權限，並反映申請結果', () async {
      when(() => service.checkAvailability()).thenAnswer((_) async => true);
      when(() => service.hasPermissions()).thenAnswer((_) async => false);
      when(() => service.requestPermissions()).thenAnswer((_) async => true);
      when(
        () => service.hasActivityRecognitionPermission(),
      ).thenAnswer((_) async => false);
      when(
        () => service.requestActivityRecognitionPermission(),
      ).thenAnswer((_) async => false);
      final controller = StepTrackingController(service);
      await _flush();
      expect(controller.state.hasHealthConnectPermission, isTrue);
      expect(controller.state.hasSensorPermission, isFalse);
      verify(() => service.requestPermissions()).called(1);
      verify(() => service.requestActivityRecognitionPermission()).called(1);
      controller.dispose();
    });
  });

  group('StepTrackingController.onPlaybackStarted', () {
    test('尚未就緒（權限不足）時，不會開始任何追蹤', () async {
      final controller = await buildReadyController(hasSensorPermission: false);
      controller.onPlaybackStarted('測試導覽');
      expect(controller.state.isTracking, isFalse);
      verifyNever(() => service.startStepSensorTracking());
      controller.dispose();
    });

    test('第一次呼叫會開始新的 sensor session，並立刻抓一次目前步數', () async {
      when(() => service.startStepSensorTracking()).thenAnswer((_) async {});
      when(() => service.getCurrentSensorSteps()).thenAnswer((_) async => 42);
      final controller = await buildReadyController();
      controller.onPlaybackStarted('測試導覽');
      await _flush();
      expect(controller.state.isTracking, isTrue);
      expect(controller.state.steps, 42);
      expect(controller.state.distance, closeTo(42 * 0.78, 0.0001));
      verify(() => service.startStepSensorTracking()).called(1);
      verifyNever(() => service.resumeStepSensorTracking());
      controller.dispose();
    });

    test('同一個 session 內再次呼叫會改用 resume，而不是重新 start', () async {
      when(() => service.startStepSensorTracking()).thenAnswer((_) async {});
      when(() => service.resumeStepSensorTracking()).thenAnswer((_) async {});
      when(() => service.getCurrentSensorSteps()).thenAnswer((_) async => 10);
      final controller = await buildReadyController();
      controller.onPlaybackStarted('測試導覽');
      await _flush();
      controller.onPlaybackStarted(
        '測試導覽',
      ); // onPlaybackCompleted hasn't been called yet, so this is considered the same session
      verify(() => service.startStepSensorTracking()).called(1);
      verify(() => service.resumeStepSensorTracking()).called(1);
      controller.dispose();
    });

    test('抓取即時步數失敗時會被安靜吞掉，不會讓例外往外拋', () async {
      when(() => service.startStepSensorTracking()).thenAnswer((_) async {});
      when(
        () => service.getCurrentSensorSteps(),
      ).thenThrow(Exception('sensor error'));
      final controller = await buildReadyController();
      controller.onPlaybackStarted('測試導覽');
      await _flush();
      expect(
        controller.state.steps,
        0,
      ); // remains the default value; not corrupted by the exception
      controller.dispose();
    });
  });

  group('StepTrackingController.onPlaybackPaused', () {
    test('會停止計時並暫停 sensor 追蹤', () async {
      when(() => service.startStepSensorTracking()).thenAnswer((_) async {});
      when(() => service.getCurrentSensorSteps()).thenAnswer((_) async => 5);
      when(() => service.pauseStepSensorTracking()).thenAnswer((_) async {});
      final controller = await buildReadyController();
      controller.onPlaybackStarted('測試導覽');
      await _flush();
      controller.onPlaybackPaused();
      expect(controller.state.isTracking, isFalse);
      verify(() => service.pauseStepSensorTracking()).called(1);
      controller.dispose();
    });
  });

  group('StepTrackingController.onPlaybackCompleted', () {
    test('沒有進行中的 session 時回傳 null，不會寫入紀錄', () async {
      final controller = await buildReadyController();
      final result = await controller.onPlaybackCompleted();
      expect(result, isNull);
      verifyNever(() => service.writeExerciseSession(any()));
      controller.dispose();
    });

    test('未就緒（權限不足）時回傳 null', () async {
      final controller = await buildReadyController(hasSensorPermission: false);
      final result = await controller.onPlaybackCompleted();
      expect(result, isNull);
      controller.dispose();
    });

    test('sensor 來源：結束時停止追蹤、寫入紀錄，並回傳正確的摘要', () async {
      when(() => service.startStepSensorTracking()).thenAnswer((_) async {});
      when(() => service.getCurrentSensorSteps()).thenAnswer((_) async => 20);
      when(() => service.stopStepSensorTracking()).thenAnswer((_) async => 100);
      when(() => service.writeExerciseSession(any())).thenAnswer((_) async {});
      final controller = await buildReadyController();
      controller.onPlaybackStarted('晨間導覽');
      await _flush();
      final result = await controller.onPlaybackCompleted();
      expect(result, isNotNull);
      expect(result!.guideName, '晨間導覽');
      expect(result.steps, 100);
      expect(result.distanceMeters, closeTo(100 * 0.78, 0.0001));
      expect(controller.state.steps, 100);
      verify(() => service.writeExerciseSession(any())).called(1);
      // the session has ended (_sessionStart was cleared); calling again should return null
      final second = await controller.onPlaybackCompleted();
      expect(second, isNull);
      controller.dispose();
    });
  });
}
