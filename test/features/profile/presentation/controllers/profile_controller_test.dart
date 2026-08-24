import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/entities/app_user.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_travel_audio_guide/features/profile/di/profile_providers.dart';
import 'package:flutter_travel_audio_guide/features/profile/domain/entities/profile.dart';
import 'package:flutter_travel_audio_guide/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_travel_audio_guide/features/profile/presentation/controllers/profile_controller.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(
    this._controller, {
    this.initialIsSignedIn = false,
  });

  final StreamController<bool> _controller;
  final bool initialIsSignedIn;

  @override
  AppUser? get currentUser => null;

  @override
  bool get isSignedIn => initialIsSignedIn;

  @override
  Stream<bool> get authStateChanges => _controller.stream;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<bool> signUpWithPassword({
    required String email,
    required String password,
  }) async => true;

  @override
  Future<void> signOut() async {}
}

Profile buildProfile({
  String displayName = 'Sun',
}) {
  final now = DateTime(2026);
  return Profile(
    id: 'uid-1',
    email: 'a@b.com',
    displayName: displayName,
    preferredLanguage: 'zh-TW',
    createdAt: now,
    updatedAt: now,
  );
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({
    this.getMeResult,
  });

  Profile? getMeResult;

  int getMeCallCount = 0;
  int updateMeCallCount = 0;

  /// When true, updateMe() returns manually controlled Futures.
  /// This allows tests to simulate out-of-order network responses.
  bool useManualUpdateGates = false;

  final List<Completer<Profile>> updateCompleters = [];

  /// In normal mode, results are returned in call order.
  /// Put an Exception into this list to simulate a failed request.
  final List<Object> updateMeResults = [];

  @override
  Future<Profile> getMe() async {
    getMeCallCount++;
    return getMeResult ?? buildProfile();
  }

  @override
  Future<Profile> updateMe({
    String? displayName,
    String? avatarUrl,
    String? preferredLanguage,
  }) {
    updateMeCallCount++;
    if (useManualUpdateGates) {
      final completer = Completer<Profile>();
      updateCompleters.add(completer);
      return completer.future;
    }
    final result = updateMeResults[updateMeCallCount - 1];
    if (result is Exception) {
      return Future.error(result);
    }
    return Future.value(result as Profile);
  }
}

void main() {
  ProviderContainer buildContainer({
    required StreamController<bool> authController,
    required FakeProfileRepository profileRepository,
    bool initialIsSignedIn = false,
  }) {
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            authController,
            initialIsSignedIn: initialIsSignedIn,
          ),
        ),
        profileRepositoryProvider.overrideWithValue(
          profileRepository,
        ),
      ],
    );
  }

  test('初始已登入時自動呼叫 getMe() 取得 profile', () async {
    final authController = StreamController<bool>();
    final profileRepository = FakeProfileRepository(
      getMeResult: buildProfile(
        displayName: 'Sun2',
      ),
    );
    final container = buildContainer(
      authController: authController,
      profileRepository: profileRepository,
      initialIsSignedIn: true,
    );
    addTearDown(() {
      container.dispose();
      authController.close();
    });
    final profile = await container.read(profileControllerProvider.future);
    expect(profile?.displayName, 'Sun2');
    expect(profileRepository.getMeCallCount, 1);
  });

  test('未登入時不會呼叫 getMe()，state 為 null', () async {
    final authController = StreamController<bool>();
    final profileRepository = FakeProfileRepository();
    final container = buildContainer(
      authController: authController,
      profileRepository: profileRepository,
    );
    addTearDown(() {
      container.dispose();
      authController.close();
    });
    final profile = await container.read(profileControllerProvider.future);
    expect(profile, isNull);
    expect(profileRepository.getMeCallCount, 0);
  });

  test('從未登入切換為登入時，會自動呼叫 getMe()', () async {
    final authController = StreamController<bool>();
    final profileRepository = FakeProfileRepository(
      getMeResult: buildProfile(
        displayName: 'Sun2',
      ),
    );
    final container = buildContainer(
      authController: authController,
      profileRepository: profileRepository,
    );
    addTearDown(() {
      container.dispose();
      authController.close();
    });
    final initialProfile = await container.read(
      profileControllerProvider.future,
    );
    expect(initialProfile, isNull);
    expect(profileRepository.getMeCallCount, 0);
    authController.add(true);
    await Future<void>.delayed(Duration.zero);
    final profile = await container.read(profileControllerProvider.future);
    expect(profile?.displayName, 'Sun2');
    expect(profileRepository.getMeCallCount, 1);
  });

  test('updateProfile 成功時 state 更新為最新資料', () async {
    final authController = StreamController<bool>();
    final profileRepository =
        FakeProfileRepository(
            getMeResult: buildProfile(),
          )
          ..updateMeResults.add(
            buildProfile(
              displayName: 'Sun2',
            ),
          );
    final container = buildContainer(
      authController: authController,
      profileRepository: profileRepository,
      initialIsSignedIn: true,
    );
    addTearDown(() {
      container.dispose();
      authController.close();
    });
    await container.read(profileControllerProvider.future);
    await container
        .read(profileControllerProvider.notifier)
        .updateProfile(
          displayName: 'Sun2',
        );
    final state = container.read(profileControllerProvider);
    expect(
      state.value?.displayName,
      'Sun2',
    );
    expect(
      state.hasError,
      isFalse,
    );
  });

  test(
    'updateProfile 失敗時，state 保留錯誤，不會被吞掉換成舊資料',
    () async {
      final authController = StreamController<bool>();
      final profileRepository =
          FakeProfileRepository(
              getMeResult: buildProfile(),
            )
            ..updateMeResults.add(
              Exception('update failed'),
            );
      final container = buildContainer(
        authController: authController,
        profileRepository: profileRepository,
        initialIsSignedIn: true,
      );
      addTearDown(() {
        container.dispose();
        authController.close();
      });
      await container.read(
        profileControllerProvider.future,
      );
      await container
          .read(profileControllerProvider.notifier)
          .updateProfile(
            displayName: 'Sun2',
          );
      final state = container.read(profileControllerProvider);
      expect(
        state.hasError,
        isTrue,
      );
    },
  );

  test(
    '較舊的 updateProfile 回應晚到時，不會蓋掉較新的結果',
    () async {
      final authController = StreamController<bool>();
      final profileRepository = FakeProfileRepository(
        getMeResult: buildProfile(),
      )..useManualUpdateGates = true;
      final container = buildContainer(
        authController: authController,
        profileRepository: profileRepository,
        initialIsSignedIn: true,
      );
      addTearDown(() {
        container.dispose();
        authController.close();
      });
      await container.read(
        profileControllerProvider.future,
      );
      final notifier = container.read(
        profileControllerProvider.notifier,
      );
      final firstUpdate = notifier.updateProfile(
        displayName: 'Old',
      );
      await Future<void>.delayed(
        Duration.zero,
      );
      final secondUpdate = notifier.updateProfile(
        displayName: 'New',
      );
      await Future<void>.delayed(
        Duration.zero,
      );
      expect(
        profileRepository.updateCompleters.length,
        2,
      );
      // Complete the newer request first.
      profileRepository.updateCompleters[1].complete(
        buildProfile(
          displayName: 'New',
        ),
      );
      await secondUpdate;
      // Then complete the older request.
      profileRepository.updateCompleters[0].complete(
        buildProfile(
          displayName: 'Old',
        ),
      );
      await firstUpdate;
      final state = container.read(profileControllerProvider);
      expect(
        state.value?.displayName,
        'New',
      );
    },
  );
}
