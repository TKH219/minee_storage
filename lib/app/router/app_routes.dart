/// Single source of truth for route paths and names.
///
/// Navigate by name (`context.goNamed(AppRoutes.homeName)`) so a path change
/// never means touching call sites.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String splashName = 'splash';

  static const String signIn = '/sign-in';
  static const String signInName = 'signIn';

  static const String signUp = '/sign-up';
  static const String signUpName = 'signUp';

  static const String forgotPassword = '/forgot-password';
  static const String forgotPasswordName = 'forgotPassword';

  static const String home = '/home';
  static const String homeName = 'home';
}
