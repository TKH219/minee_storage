import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/features/auth/forgot_password/pages/forgot_password_page.dart';
import 'package:mine_storage/features/auth/sign_in/pages/sign_in_page.dart';
import 'package:mine_storage/features/auth/sign_up/pages/sign_up_page.dart';
import 'package:mine_storage/features/dashboard/pages/dashboard_page.dart';
import 'package:mine_storage/features/home/pages/home_page.dart';
import 'package:mine_storage/features/onboarding/create_store/pages/create_store_page.dart';
import 'package:mine_storage/features/onboarding/profile/pages/profile_page.dart';
import 'package:mine_storage/features/products/detail/pages/product_detail_page.dart';
import 'package:mine_storage/features/products/form/pages/product_form_page.dart';
import 'package:mine_storage/features/products/pages/product_list_page.dart';
import 'package:mine_storage/features/products/scan/pages/scan_page.dart';
import 'package:mine_storage/features/reports/pages/reports_page.dart';
import 'package:mine_storage/features/sales/pages/sales_list_page.dart';
import 'package:mine_storage/features/shell/pages/main_shell_page.dart';
import 'package:mine_storage/features/splash/pages/splash_page.dart';
import 'package:mine_storage/shared/utils/logger.dart';

import 'app_routes.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/features/settings/pages/settings_page.dart';

/// Held globally so non-widget code (interceptors) can navigate.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: AppRoutes.signInName,
        pageBuilder: (context, state) => _fadePage(
          state,
          SignInPage(
            prefilledEmail: state.uri.queryParameters['email'],
            passwordWasReset: state.uri.queryParameters['reset'] == 'true',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: AppRoutes.signUpName,
        pageBuilder: (context, state) => _fadePage(state, const SignUpPage()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPasswordName,
        pageBuilder: (context, state) => _fadePage(state, const ForgotPasswordPage()),
      ),
      GoRoute(
        path: AppRoutes.onboardingProfile,
        name: AppRoutes.onboardingProfileName,
        pageBuilder: (context, state) => _fadePage(state, const ProfilePage()),
      ),
      GoRoute(
        path: AppRoutes.createStore,
        name: AppRoutes.createStoreName,
        pageBuilder: (context, state) => _fadePage(state, const CreateStorePage()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        builder: (context, state) => const SettingsPage(),
      ),
      // Ahead of the shell so the form covers the nav bar, and `new` before
      // any `/products/:id` route so it is not read as an id.
      GoRoute(
        path: AppRoutes.productNew,
        name: AppRoutes.productNewName,
        builder: (context, state) => ProductFormPage(
          initialBarcode: state.uri.queryParameters['barcode'],
        ),
      ),
      GoRoute(
        path: AppRoutes.productScan,
        name: AppRoutes.productScanName,
        builder: (context, state) => const ScanPage(),
      ),
      GoRoute(
        path: AppRoutes.productEdit,
        name: AppRoutes.productEditName,
        builder: (context, state) =>
            ProductFormPage(productId: state.pathParameters['id']),
      ),
      // Last of the /products/* group: `:id` would otherwise swallow `new`.
      GoRoute(
        path: AppRoutes.productDetail,
        name: AppRoutes.productDetailName,
        builder: (context, state) =>
            ProductDetailPage(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        pageBuilder: (context, state) => _fadePage(state, const HomePage()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellPage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: AppRoutes.dashboardName,
              builder: (context, state) => const DashboardPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.products,
              name: AppRoutes.productsName,
              builder: (context, state) => const ProductListPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.sales,
              name: AppRoutes.salesName,
              builder: (context, state) => const SalesListPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.reports,
              name: AppRoutes.reportsName,
              builder: (context, state) => const ReportsPage(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      logger.e(LocaleKeys.router_unknownRoute.tr(namedArgs: {'uri': '${state.uri}'}), error: state.error);
      return const _RouteNotFoundPage();
    },
  );
});


/// Replaces popular_sg_mobile's `FadePageRoute` — same transition, expressed as
/// a go_router page.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _RouteNotFoundPage extends StatelessWidget {
  const _RouteNotFoundPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(LocaleKeys.router_pageNotFound.tr()),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.goNamed(AppRoutes.homeName),
              child: Text(LocaleKeys.router_goHome.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
