/// Single source of truth for route paths and names.
///
/// Navigate by name (`context.goNamed(AppRoutes.homeName)`) so a path change
/// never means touching call sites.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String splashName = 'splash';

  static const String login = '/login';
  static const String loginName = 'login';

  static const String home = '/home';
  static const String homeName = 'home';
}
