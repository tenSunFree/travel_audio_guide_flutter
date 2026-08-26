import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/entities/app_user.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_travel_audio_guide/features/auth/presentation/pages/login_page.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.signUpResult = true});

  final bool signUpResult;
  final List<String> signInEmails = [];
  final List<String> signUpEmails = [];

  /// After setting this, signInWithPassword will wait on this Completer before completing,
  /// used to test the "loading indicator shown during submission" state.
  Completer<void>? signInGate;

  @override
  AppUser? get currentUser => null;

  @override
  bool get isSignedIn => false;

  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInEmails.add(email);
    if (signInGate != null) {
      await signInGate!.future;
    }
  }

  @override
  Future<bool> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    signUpEmails.add(email);
    return signUpResult;
  }

  @override
  Future<void> signOut() async {}
}

Widget buildSubject(FakeAuthRepository repository) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: LoginPage()),
  );
}

void main() {
  testWidgets('顯示登入頁初始內容', (tester) async {
    await tester.pumpWidget(buildSubject(FakeAuthRepository()));
    expect(find.text('歡迎回來'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '登入'), findsOneWidget);
    expect(find.text('還沒有帳號？前往註冊'), findsOneWidget);
  });

  testWidgets('Email 格式錯誤時顯示驗證訊息，不會呼叫 signIn', (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(buildSubject(repository));
    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.widgetWithText(FilledButton, '登入'));
    await tester.pump();
    expect(find.text('請輸入有效的 Email'), findsOneWidget);
    expect(repository.signInEmails, isEmpty);
  });

  testWidgets('密碼過短時顯示驗證訊息，不會呼叫 signIn', (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(buildSubject(repository));
    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.tap(find.widgetWithText(FilledButton, '登入'));
    await tester.pump();
    expect(find.text('密碼至少需要 6 碼'), findsOneWidget);
    expect(repository.signInEmails, isEmpty);
  });

  testWidgets('輸入正確格式後送出，呼叫 signInWithPassword', (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(buildSubject(repository));
    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.widgetWithText(FilledButton, '登入'));
    await tester.pumpAndSettle();
    expect(repository.signInEmails, ['a@b.com']);
  });

  testWidgets('點擊「還沒有帳號？前往註冊」切換到註冊模式', (tester) async {
    await tester.pumpWidget(buildSubject(FakeAuthRepository()));
    await tester.tap(find.text('還沒有帳號？前往註冊'));
    await tester.pump();
    expect(find.text('建立帳號'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '註冊'), findsOneWidget);
    expect(find.text('已經有帳號？改為登入'), findsOneWidget);
  });

  testWidgets('註冊模式下送出，呼叫 signUpWithPassword', (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(buildSubject(repository));
    await tester.tap(find.text('還沒有帳號？前往註冊'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.widgetWithText(FilledButton, '註冊'));
    await tester.pumpAndSettle();
    expect(repository.signUpEmails, ['a@b.com']);
  });

  testWidgets('註冊後需要 Email 驗證時顯示提示 SnackBar', (tester) async {
    final repository = FakeAuthRepository(signUpResult: false);
    await tester.pumpWidget(buildSubject(repository));
    await tester.tap(find.text('還沒有帳號？前往註冊'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.widgetWithText(FilledButton, '註冊'));
    await tester.pumpAndSettle();
    expect(find.text('註冊成功，請至信箱完成驗證後登入'), findsOneWidget);
  });

  testWidgets('已直接取得 session 時不顯示 Email 驗證提示', (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(buildSubject(repository));
    await tester.tap(find.text('還沒有帳號？前往註冊'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.widgetWithText(FilledButton, '註冊'));
    await tester.pumpAndSettle();
    expect(find.text('註冊成功，請至信箱完成驗證後登入'), findsNothing);
  });

  testWidgets('送出期間顯示 loading indicator 並停用按鈕', (tester) async {
    final repository = FakeAuthRepository()..signInGate = Completer<void>();
    await tester.pumpWidget(buildSubject(repository));
    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.widgetWithText(FilledButton, '登入'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    repository.signInGate!.complete();
    await tester.pumpAndSettle();
  });
}
