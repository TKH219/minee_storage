import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/utils/logger.dart';

final splashStateProvider = AutoDisposeNotifierProvider<SplashStateNotifier, SplashState>(
  SplashStateNotifier.new,
);

class SplashState extends BaseState with Equatable {
  const SplashState({super.status, super.errorMessageKey, super.errorMessage});

  @override
  SplashState copyWith({StateLifeCycle? status, String? errorMessageKey,
    String? errorMessage}) {
    return SplashState(
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessageKey, errorMessage];
}

/// The app's only session gate. The router has no `redirect`, so every decision
/// about where a session may take the user is made here.
///
/// Losing a session mid-use routes back to splash, which re-runs this — that is
/// what keeps the rule in one place instead of duplicating it in a redirect.
String resolveStartRoute({required bool loggedIn}) =>
    loggedIn ? AppRoutes.homeName : AppRoutes.signInName;

class SplashStateNotifier extends BaseStateNotifier<SplashState> {
  late final AuthRepository _authRepository;

  @override
  SplashState createInitialState() {
    _authRepository = ref.read(authRepositoryProvider);
    return const SplashState();
  }

  /// Decides the first real screen from the restored Supabase session.
  Future<void> bootstrap() async {
    showLoading();
    try {
      final user = await _authRepository.currentUser();
      showLoaded();
      router()?.goNamed(resolveStartRoute(loggedIn: user != null));
    } on Object catch (e) {
      logger.e('Splash bootstrap failed', error: e);
      showLoaded();
      router()?.goNamed(resolveStartRoute(loggedIn: false));
    }
  }
}
