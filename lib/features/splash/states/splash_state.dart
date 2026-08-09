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
  const SplashState({super.status, super.errorMessage});

  @override
  SplashState copyWith({StateLifeCycle? status, String? errorMessage}) {
    return SplashState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}

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
      router()?.goNamed(user == null ? AppRoutes.signInName : AppRoutes.homeName);
    } on Object catch (e) {
      logger.e('Splash bootstrap failed', error: e);
      showLoaded();
      router()?.goNamed(AppRoutes.signInName);
    }
  }
}
