import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/base/base_state.dart';

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
  @override
  SplashState createInitialState() => const SplashState();

  /// Decides the first real screen.
  ///
  /// The demo slice is public, so it always lands on home. Swap the branch back
  /// on once the real API requires a session.
  Future<void> bootstrap() async {
    showLoading();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    showLoaded();
    router()?.goNamed(AppRoutes.homeName);
  }
}
