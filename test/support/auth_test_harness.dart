import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_routes.dart';

/// Mirrors the real route table by name and path, with inert builders, so
/// notifier tests can assert navigation without mounting real pages.
GoRouter buildTestRouter() {
  Widget stub(BuildContext context, GoRouterState state) => const SizedBox.shrink();

  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, name: AppRoutes.splashName, builder: stub),
      GoRoute(path: AppRoutes.signIn, name: AppRoutes.signInName, builder: stub),
      GoRoute(path: AppRoutes.signUp, name: AppRoutes.signUpName, builder: stub),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPasswordName,
        builder: stub,
      ),
      GoRoute(path: AppRoutes.home, name: AppRoutes.homeName, builder: stub),
    ],
  );
}

/// Reads the route information provider rather than `currentConfiguration`,
/// which stays empty until the router is mounted by a widget tree.
String currentPath(GoRouter router) =>
    router.routeInformationProvider.value.uri.path;
