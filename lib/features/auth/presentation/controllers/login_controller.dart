import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/auth/presentation/controllers/login_state.dart';

class LoginController extends StateNotifier<LoginState> {
  LoginController({required this.ref}) : super(const LoginState());

  final Ref ref;

  Future<void> signIn({required String email, required String password}) {
    return _submit(
      () => ref
          .read(authRepositoryProvider)
          .signInWithPassword(email: email, password: password),
    );
  }

  Future<void> signUp({required String email, required String password}) {
    return _submit(
      () => ref
          .read(authRepositoryProvider)
          .signUpWithPassword(email: email, password: password),
    );
  }

  Future<void> _submit(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await action();
      // After successful sign-in, authStateChangesProvider will emit the new state,
      // and the router's redirect will navigate to the home page.
      // No manual context.go() is needed here.
      state = state.copyWith(isLoading: false, isSuccess: true);
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
      state = state.copyWith(isLoading: false, errorMessage: '登入失敗，請稍後再試');
    }
  }
}

final AutoDisposeStateNotifierProvider<LoginController, LoginState>
loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
      return LoginController(ref: ref);
    });
