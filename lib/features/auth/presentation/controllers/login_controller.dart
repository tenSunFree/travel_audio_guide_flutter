import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/auth/presentation/controllers/login_state.dart';

class LoginController extends StateNotifier<LoginState> {
  LoginController({required this.ref}) : super(const LoginState());

  final Ref ref;

  Future<void> signIn({required String email, required String password}) {
    return _submit(() async {
      await ref
          .read(authRepositoryProvider)
          .signInWithPassword(email: email, password: password);
      // There is never an intermediate "needs email confirmation" state for sign-in.
      return false;
    });
  }

  Future<void> signUp({required String email, required String password}) {
    return _submit(
      () => ref
          .read(authRepositoryProvider)
          .signUpWithPassword(email: email, password: password)
          // The repository returns true to indicate a session was obtained
          // immediately after sign-up. For the UI we invert this: hasSession == false
          // means we need to prompt the user to check their email for confirmation.
          .then((hasSession) => !hasSession),
    );
  }

  Future<void> _submit(Future<bool> Function() action) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final needsEmailConfirmation = await action();
      // After successful sign-in / sign-up:
      // - authStateChangesProvider will automatically emit a new state if a
      //   session was obtained.
      // - If no session was obtained (needsEmailConfirmation == true), the
      //   Router's redirect won't be triggered and the UI stays on the login
      //   page so we can show a prompt.
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        needsEmailConfirmation: needsEmailConfirmation,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.map(
          server: (e) => e.message,
          download: (e) => e.message,
          localStorage: (e) => e.message,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '登入失敗，請稍後再試',
      );
    }
  }
}

final AutoDisposeStateNotifierProvider<LoginController, LoginState>
loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
      return LoginController(ref: ref);
    });
