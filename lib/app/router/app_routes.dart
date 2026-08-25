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

  static const String onboardingProfile = '/onboarding/profile';
  static const String onboardingProfileName = 'onboardingProfile';

  static const String createStore = '/onboarding/store';
  static const String createStoreName = 'createStore';

  static const String home = '/home';
  static const String homeName = 'home';

  static const String dashboard = '/dashboard';
  static const String dashboardName = 'dashboard';

  static const String products = '/products';
  static const String productsName = 'products';

  /// Registered before `/products/:id` in the router — otherwise `new` is
  /// swallowed as an id.
  static const String productNew = '/products/new';
  static const String productNewName = 'productNew';

  static const String productScan = '/products/scan';
  static const String productScanName = 'productScan';

  static const String productEdit = '/products/:id/edit';
  static const String productEditName = 'productEdit';

  static const String productDetail = '/products/:id';
  static const String productDetailName = 'productDetail';

  static const String sales = '/sales';
  static const String salesName = 'sales';

  static const String reports = '/reports';
  static const String reportsName = 'reports';

  static const String settings = '/settings';
  static const String settingsName = 'settings';
}
