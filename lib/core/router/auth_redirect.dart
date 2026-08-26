/// Pure redirect rules for onboarding + Supabase auth.
///
/// Extracted from appRouterProvider so the decision table can be unit-tested
/// without spinning up GoRouter, Firebase observers, or widget trees.
String? resolveAuthRedirect({
  required bool hasSeenWelcome,
  required bool signedIn,
  required String location,
  String splash = '/splash',
  String welcome = '/welcome',
  String login = '/login',
  String home = '/',
}) {
  // Splash owns its own navigation timing.
  if (location == splash) {
    return null;
  }
  // First launch: everything except welcome goes to welcome.
  if (!hasSeenWelcome && location != welcome) {
    return welcome;
  }
  // Welcome already seen, but the user is still on welcome.
  if (hasSeenWelcome && location == welcome) {
    return signedIn ? home : login;
  }
  // Signed-out users may only stay on the login page.
  if (hasSeenWelcome && !signedIn && location != login) {
    return login;
  }
  // Signed-in users should not stay on login.
  if (signedIn && location == login) {
    return home;
  }
  return null;
}
