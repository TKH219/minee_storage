import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/extensions/string_extensions.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/providers.dart';

final loginStateProvider = AutoDisposeNotifierProvider<LoginStateNotifier, LoginState>(
  LoginStateNotifier.new,
);

class LoginState extends BaseState with Equatable {
  const LoginState({
    this.username = '',
    this.password = '',
    this.obscurePassword = true,
    super.status,
    super.errorMessage,
  });

  final String username;
  final String password;
  final bool obscurePassword;

  bool get canSubmit => username.isNotBlank && password.isNotBlank && !isLoading;

  @override
  LoginState copyWith({
    StateLifeCycle? status,
    String? errorMessage,
    String? username,
    String? password,
    bool? obscurePassword,
  }) {
    return LoginState(
      username: username ?? this.username,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [username, password, obscurePassword, status, errorMessage];
}

class LoginStateNotifier extends BaseStateNotifier<LoginState> {
  late final AuthRepository _authRepository;

  @override
  LoginState createInitialState() {
    _authRepository = ref.read(authRepositoryProvider);
    return const LoginState();
  }

  void updateUsername(String value) => updateState(state.copyWith(username: value));

  void updatePassword(String value) => updateState(state.copyWith(password: value));

  void togglePasswordVisibility() =>
      updateState(state.copyWith(obscurePassword: !state.obscurePassword));

  Future<void> login() async {
    if (!state.canSubmit) {
      showSnackError(msg: 'Please enter your username and password.');
      return;
    }

    try {
      showLoading();
      await _authRepository.logIn(
        username: state.username.trim().toLowerCase(),
        password: state.password.trim(),
      );
      showLoaded();
      router()?.goNamed(AppRoutes.homeName);
    } on Object catch (e) {
      onError(e);
    }
  }
}
