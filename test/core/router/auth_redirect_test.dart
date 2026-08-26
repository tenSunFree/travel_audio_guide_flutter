import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/router/auth_redirect.dart';

void main() {
  group('resolveAuthRedirect', () {
    test('splash 一律不介入', () {
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: false,
          signedIn: false,
          location: '/splash',
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: true,
          location: '/splash',
        ),
        isNull,
      );
    });

    test('還沒看過 welcome 時，非 welcome 路徑都導向 welcome', () {
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: false,
          signedIn: false,
          location: '/',
        ),
        '/welcome',
      );
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: false,
          signedIn: false,
          location: '/login',
        ),
        '/welcome',
      );
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: false,
          signedIn: false,
          location: '/welcome',
        ),
        isNull,
      );
    });

    test('已看過 welcome 且仍停在 welcome 時，依登入狀態分流', () {
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: true,
          location: '/welcome',
        ),
        '/',
      );
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: false,
          location: '/welcome',
        ),
        '/login',
      );
    });

    test('已看過 welcome 且未登入時，非 login 路徑都導向 login', () {
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: false,
          location: '/',
        ),
        '/login',
      );
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: false,
          location: '/attractions',
        ),
        '/login',
      );
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: false,
          location: '/login',
        ),
        isNull,
      );
    });

    test('已登入卻停在 login 時導向 home', () {
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: true,
          location: '/login',
        ),
        '/',
      );
    });

    test('已登入且不在 login 時不介入', () {
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: true,
          location: '/',
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: true,
          location: '/attractions',
        ),
        isNull,
      );
    });
  });
}
