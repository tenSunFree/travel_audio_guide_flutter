import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/repositories/reminder_repository.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/services/notification_service.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/usecases/create_reminder_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockReminderRepository extends Mock implements ReminderRepository {}

class MockNotificationService extends Mock implements NotificationService {}

class _FakeReminder extends Fake implements Reminder {}

Reminder _withId(Reminder r, int id) {
  return Reminder(
    id: id,
    sourceType: r.sourceType,
    sourceId: r.sourceId,
    title: r.title,
    subtitle: r.subtitle,
    imageUrl: r.imageUrl,
    address: r.address,
    targetTime: r.targetTime,
    remindBeforeSeconds: r.remindBeforeSeconds,
    notifyTime: r.notifyTime,
    notificationId: r.notificationId,
    routePath: r.routePath,
    payloadJson: r.payloadJson,
    isEnabled: r.isEnabled,
    isDone: r.isDone,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}

void main() {
  late MockReminderRepository repository;
  late MockNotificationService notificationService;
  late CreateReminderUseCase useCase;

  setUpAll(() {
    registerFallbackValue(_FakeReminder());
  });

  setUp(() {
    repository = MockReminderRepository();
    notificationService = MockNotificationService();
    useCase = CreateReminderUseCase(repository, notificationService);
  });

  final futureTime = DateTime.now().add(const Duration(days: 1));

  CreateReminderParams buildParams({
    String sourceType = 'attraction',
    String sourceId = 'A001',
    DateTime? targetTime,
    int remindBeforeSeconds = 3600,
  }) {
    return CreateReminderParams(
      sourceType: sourceType,
      sourceId: sourceId,
      title: '測試景點',
      subtitle: '副標題',
      imageUrl: 'https://example.com/img.png',
      address: '台北市信義區',
      targetTime: targetTime ?? futureTime,
      remindBeforeSeconds: remindBeforeSeconds,
    );
  }

  group('CreateReminderUseCase', () {
    test('成功建立提醒：呼叫 repository.createReminder 並排程通知', () async {
      when(() => repository.createReminder(any())).thenAnswer((
        invocation,
      ) async {
        final r = invocation.positionalArguments.first as Reminder;
        return _withId(r, 1);
      });
      when(
        () => notificationService.scheduleReminder(any()),
      ).thenAnswer((_) async {});
      final params = buildParams();
      await useCase(params);
      final saved =
          verify(() => repository.createReminder(captureAny())).captured.single
              as Reminder;
      expect(saved.routePath, '/attractions/A001');
      expect(saved.isEnabled, isTrue);
      expect(saved.isDone, isFalse);
      expect(
        saved.notifyTime,
        params.targetTime.subtract(const Duration(seconds: 3600)),
      );
      final scheduled =
          verify(
                () => notificationService.scheduleReminder(captureAny()),
              ).captured.single
              as Reminder;
      expect(scheduled.id, 1);
    });

    test('sourceType 為 activity / audioGuide 時會產生對應路由', () async {
      when(() => repository.createReminder(any())).thenAnswer(
        (invocation) async => invocation.positionalArguments.first as Reminder,
      );
      when(
        () => notificationService.scheduleReminder(any()),
      ).thenAnswer((_) async {});
      await useCase(buildParams(sourceType: 'activity', sourceId: 'X1'));
      var saved =
          verify(() => repository.createReminder(captureAny())).captured.last
              as Reminder;
      expect(saved.routePath, '/activities/X1');
      await useCase(buildParams(sourceType: 'audioGuide', sourceId: 'Y1'));
      saved =
          verify(() => repository.createReminder(captureAny())).captured.last
              as Reminder;
      expect(saved.routePath, '/audio-guides/Y1');
    });

    test('不支援的 sourceType 會拋出例外，且不會呼叫 repository', () async {
      await expectLater(
        useCase(buildParams(sourceType: 'unknown')),
        throwsA(isA<Exception>()),
      );
      verifyNever(() => repository.createReminder(any()));
    });

    test('提醒時間已經過了會拋出例外，且不會呼叫 repository', () async {
      final pastParams = buildParams(
        targetTime: DateTime.now().add(const Duration(seconds: 1)),
      );
      await expectLater(useCase(pastParams), throwsA(isA<Exception>()));
      verifyNever(() => repository.createReminder(any()));
    });

    test('排程通知失敗時，會刪除已建立的提醒並重新拋出例外', () async {
      when(() => repository.createReminder(any())).thenAnswer((
        invocation,
      ) async {
        final r = invocation.positionalArguments.first as Reminder;
        return _withId(r, 99);
      });
      when(
        () => notificationService.scheduleReminder(any()),
      ).thenThrow(Exception('notify failed'));
      when(() => repository.deleteReminder(any())).thenAnswer((_) async {});
      await expectLater(useCase(buildParams()), throwsA(isA<Exception>()));
      verify(() => repository.deleteReminder(99)).called(1);
    });
  });
}
