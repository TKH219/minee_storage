import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/extensions/string_extensions.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/providers.dart';

final signInStateProvider = AutoDisposeNotifierProvider<SignInStateNotifier, SignInState>(
  SignInStateNotifier.new,
);

/// The design gives sign-in two error surfaces in different places, and the
/// split is deliberate: a rejected credential sits under the password it
/// refers to, while a deactivated account is a property of the whole account
/// and sits above the form.
enum AuthErrorPlacement { none, belowPassword, aboveEmail }

class SignInState extends BaseState with Equatable {
  const SignInState({
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    this.errorPlacement = AuthErrorPlacement.none,
    super.status,
    super.errorMessage,
  });

  final String email;
  final String password;
  final bool obscurePassword;
  final AuthErrorPlacement errorPlacement;

  bool get canSubmit => email.isNotBlank && password.isNotBlank && !isLoading;

  @override
  SignInState copyWith({
    StateLifeCycle? status,
    String? errorMessage,
    String? email,
    String? password,
    AuthErrorPlacement? errorPlacement,
    bool? obscurePassword,
  }) {
    return SignInState(
      email: email ?? this.email,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      errorPlacement: errorPlacement ?? this.errorPlacement,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [email, password, obscurePassword, errorPlacement, status, errorMessage];
}

class SignInStateNotifier extends BaseStateNotifier<SignInState> {
  late final AuthRepository _authRepository;

  @override
  SignInState createInitialState() {
    _authRepository = ref.read(authRepositoryProvider);
    return const SignInState();
  }

  void prefillEmail(String email) => updateState(state.copyWith(email: email));

  void updateEmail(String value) => updateState(
    state.copyWith(email: value, errorPlacement: AuthErrorPlacement.none),
  );

  void updatePassword(String value) => updateState(
    state.copyWith(password: value, errorPlacement: AuthErrorPlacement.none),
  );

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
      router()?.goNamed(AppRoutes.dashboardName);
    } on Object catch (e) {
      _handleError(e);
    }
  }

  void _handleError(Object error) {
    onError(error);
    final exception = resolveException(error);
    updateState(
      state.copyWith(
        errorPlacement: exception is ForbiddenException
            ? AuthErrorPlacement.aboveEmail
            : AuthErrorPlacement.belowPassword,
      ),
    );
  }
}
