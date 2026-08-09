import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/features/home/pages/home_page.dart';
import 'package:mine_storage/features/splash/pages/splash_page.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/utils/logger.dart';

import 'app_routes.dart';

/// Held globally so non-widget code (interceptors) can navigate.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: ref.watch(authStateListenableProvider),
    redirect: (context, state) => resolveRedirect(
      loggedIn: ref.read(supabaseClientProvider).auth.currentSession != null,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        pageBuilder: (context, state) => _fadePage(state, const HomePage()),
      ),
    ],
    errorBuilder: (context, state) {
      logger.e('Unknown route: ${state.uri}', error: state.error);
      return const _RouteNotFoundPage();
    },
  );
});

/// Pure so it can be unit-tested without a router or a session.
///
/// `/forgot-password` is deliberately reachable while signed in: verifying the
/// recovery code creates a session one step before the new password is set.
String? resolveRedirect({required bool loggedIn, required String location}) {
  if (location == AppRoutes.splash) return null;

  const authOnly = {AppRoutes.signIn, AppRoutes.signUp};

  if (!loggedIn) {
    return authOnly.contains(location) || location == AppRoutes.forgotPassword
        ? null
        : AppRoutes.signIn;
  }
  return authOnly.contains(location) ? AppRoutes.home : null;
}

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
