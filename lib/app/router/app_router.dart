import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/features/auth/forgot_password/pages/forgot_password_page.dart';
import 'package:mine_storage/features/auth/sign_in/pages/sign_in_page.dart';
import 'package:mine_storage/features/auth/sign_up/pages/sign_up_page.dart';
import 'package:mine_storage/features/dashboard/pages/dashboard_page.dart';
import 'package:mine_storage/features/home/pages/home_page.dart';
import 'package:mine_storage/features/products/pages/product_list_page.dart';
import 'package:mine_storage/features/reports/pages/reports_page.dart';
import 'package:mine_storage/features/sales/pages/sales_list_page.dart';
import 'package:mine_storage/features/shell/pages/main_shell_page.dart';
import 'package:mine_storage/features/splash/pages/splash_page.dart';
import 'package:mine_storage/shared/utils/logger.dart';

import 'app_routes.dart';

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
          SignInPage(prefilledEmail: state.uri.queryParameters['email']),
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
      logger.e('Unknown route: ${state.uri}', error: state.error);
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
            const Text('Page not found'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.goNamed(AppRoutes.homeName),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}
