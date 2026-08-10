import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/extensions/string_extensions.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/providers.dart';

final signInStateProvider = AutoDisposeNotifierProvider<SignInStateNotifier, SignInState>(
  SignInStateNotifier.new,
);

class SignInState extends BaseState with Equatable {
  const SignInState({
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    super.status,
    super.errorMessage,
  });

  final String email;
  final String password;
  final bool obscurePassword;

  bool get canSubmit => email.isNotBlank && password.isNotBlank && !isLoading;

  @override
  SignInState copyWith({
    StateLifeCycle? status,
    String? errorMessage,
    String? email,
    String? password,
    bool? obscurePassword,
  }) {
    return SignInState(
      email: email ?? this.email,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [email, password, obscurePassword, status, errorMessage];
}

class SignInStateNotifier extends BaseStateNotifier<SignInState> {
  late final AuthRepository _authRepository;

  @override
  SignInState createInitialState() {
    _authRepository = ref.read(authRepositoryProvider);
    return const SignInState();
  }

  void prefillEmail(String email) => updateState(state.copyWith(email: email));

  void updateEmail(String value) => updateState(state.copyWith(email: value));

  void updatePassword(String value) => updateState(state.copyWith(password: value));

  void togglePasswordVisibility() =>
      updateState(state.copyWith(obscurePassword: !state.obscurePassword));

  Future<void> signIn() async {
    if (!state.canSubmit) {
      showSnackError(msg: 'Please enter your email and password.');
      return;
    }

    try {
      showLoading();
      await _authRepository.signIn(email: state.email, password: state.password);
      showLoaded();
      router()?.goNamed(AppRoutes.homeName);
    } on Object catch (e) {
      _handleError(e);
    }
  }

  /// This screen has no inline error surface, so every failure is a snack —
  /// rejected credentials included, which is the common case here.
  void _handleError(Object error) {
    onError(error);
    showSnackError(msg: resolveException(error).displayMessage);
  }
}
