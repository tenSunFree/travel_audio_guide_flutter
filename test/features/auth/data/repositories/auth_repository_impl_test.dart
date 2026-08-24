import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:flutter_travel_audio_guide/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseAuthDataSource extends Mock
    implements SupabaseAuthDataSource {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockAuthState extends Mock implements AuthState {}

void main() {
  late MockSupabaseAuthDataSource dataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    dataSource = MockSupabaseAuthDataSource();
    repository = AuthRepositoryImpl(dataSource);
  });

  group('currentUser', () {
    test('dataSource 沒有登入使用者時回傳 null', () {
      when(() => dataSource.currentUser).thenReturn(null);
      expect(repository.currentUser, isNull);
    });

    test('把 supabase User 映射成 AppUser', () {
      final user = MockUser();
      when(() => user.id).thenReturn('uid-1');
      when(() => user.email).thenReturn('a@b.com');
      when(() => dataSource.currentUser).thenReturn(user);
      final appUser = repository.currentUser;
      expect(appUser?.id, 'uid-1');
      expect(appUser?.email, 'a@b.com');
    });
  });

  group('isSignedIn', () {
    test('currentSession 為 null 時回傳 false', () {
      when(() => dataSource.currentSession).thenReturn(null);
      expect(repository.isSignedIn, isFalse);
    });

    test('currentSession 有值時回傳 true', () {
      when(() => dataSource.currentSession).thenReturn(MockSession());
      expect(repository.isSignedIn, isTrue);
    });
  });

  group('authStateChanges', () {
    test('把 AuthState 映射成「session 是否存在」的 bool stream', () async {
      final signedInState = MockAuthState();
      when(() => signedInState.session).thenReturn(MockSession());
      final signedOutState = MockAuthState();
      when(() => signedOutState.session).thenReturn(null);
      when(() => dataSource.onAuthStateChange).thenAnswer(
        (_) => Stream.fromIterable([signedInState, signedOutState]),
      );
      final results = await repository.authStateChanges.toList();
      expect(results, [true, false]);
    });
  });

  group('signInWithPassword', () {
    test('轉發參數給 dataSource', () async {
      when(
        () => dataSource.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      await repository.signInWithPassword(email: 'a@b.com', password: '123456');
      verify(
        () => dataSource.signInWithPassword(
          email: 'a@b.com',
          password: '123456',
        ),
      ).called(1);
    });
  });

  group('signUpWithPassword', () {
    test('AuthResponse.session 有值時回傳 true（已直接登入）', () async {
      final response = MockAuthResponse();
      when(() => response.session).thenReturn(MockSession());
      when(
        () => dataSource.signUpWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);
      final result = await repository.signUpWithPassword(
        email: 'a@b.com',
        password: '123456',
      );
      expect(result, isTrue);
    });

    test('AuthResponse.session 為 null 時回傳 false（需要 Email 驗證）', () async {
      final response = MockAuthResponse();
      when(() => response.session).thenReturn(null);
      when(
        () => dataSource.signUpWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);
      final result = await repository.signUpWithPassword(
        email: 'a@b.com',
        password: '123456',
      );
      expect(result, isFalse);
    });
  });

  group('signOut', () {
    test('轉發給 dataSource', () async {
      when(() => dataSource.signOut()).thenAnswer((_) async {});
      await repository.signOut();
      verify(() => dataSource.signOut()).called(1);
    });
  });
}
