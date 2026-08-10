import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/extensions/string_extensions.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/features/auth/widgets/otp_field.dart';
import 'package:mine_storage/providers.dart';

enum ResetStep { email, code, newPassword }

final forgotPasswordStateProvider =
    AutoDisposeNotifierProvider<ForgotPasswordStateNotifier, ForgotPasswordState>(
      ForgotPasswordStateNotifier.new,
    );

class ForgotPasswordState extends BaseState with Equatable {
  const ForgotPasswordState({
    this.step = ResetStep.email,
    this.email = '',
    this.code = '',
    this.password = '',
    this.obscurePassword = true,
    super.status,
    super.errorMessage,
  });

  final ResetStep step;
  final String email;
  final String code;
  final String password;
  final bool obscurePassword;

  bool get canSubmitEmail => email.isNotBlank && email.contains('@') && !isLoading;

  bool get canSubmitCode => code.trim().length == OtpField.codeLength && !isLoading;

  bool get canSubmitPassword => password.trim().length >= 6 && !isLoading;

  @override
  ForgotPasswordState copyWith({
    StateLifeCycle? status,
    String? errorMessage,
    ResetStep? step,
    String? email,
    String? code,
    String? password,
    bool? obscurePassword,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      email: email ?? this.email,
      code: code ?? this.code,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    step,
    email,
    code,
    password,
    obscurePassword,
    status,
    errorMessage,
  ];
}

class ForgotPasswordStateNotifier extends BaseStateNotifier<ForgotPasswordState> {
  late final AuthRepository _authRepository;

  @override
  ForgotPasswordState createInitialState() {
    _authRepository = ref.read(authRepositoryProvider);
    return const ForgotPasswordState();
  }

  void updateEmail(String value) => updateState(state.copyWith(email: value));

  void updateCode(String value) => updateState(state.copyWith(code: value));

  void updatePassword(String value) => updateState(state.copyWith(password: value));

  void togglePasswordVisibility() =>
      updateState(state.copyWith(obscurePassword: !state.obscurePassword));

  void back() {
    final previous = switch (state.step) {
      ResetStep.newPassword => ResetStep.code,
      ResetStep.code => ResetStep.email,
      ResetStep.email => ResetStep.email,
    };
    updateState(state.copyWith(step: previous, status: StateLifeCycle.init));
  }

  Future<void> submitEmail() async {
    if (!state.canSubmitEmail) {
      showSnackError(msg: 'Enter the email you signed up with.');
      return;
    }

    try {
      showLoading();
      // Signup already exposes existence via the same RPC, so staying coy here
      // would only strand the user on a code screen no code is coming to.
      final status = await _authRepository.checkEmail(state.email);
      if (status == EmailStatus.none) {
        updateState(
          state.copyWith(
            status: StateLifeCycle.error,
            errorMessage: 'No account found for that email.',
          ),
        );
        return;
      }

      await _authRepository.startPasswordReset(state.email);
      showLoaded();
      updateState(state.copyWith(step: ResetStep.code));
    } on Object catch (e) {
      _handleError(e);
    }
  }

  Future<void> submitCode() async {
    if (!state.canSubmitCode) {
      showSnackError(msg: 'Enter the 8-digit code from your email.');
      return;
    }

    try {
      showLoading();
      await _authRepository.verifyPasswordResetCode(
        email: state.email,
        token: state.code,
      );
      showLoaded();
      updateState(state.copyWith(step: ResetStep.newPassword));
    } on Object catch (e) {
      _handleError(e);
    }
  }

  Future<void> submitNewPassword() async {
    if (!state.canSubmitPassword) {
      showSnackError(msg: 'Password must be at least 6 characters.');
      return;
    }

    try {
      showLoading();
      await _authRepository.setNewPassword(state.password);
      showLoaded();
      // setNewPassword signs out; the user re-authenticates with the new one.
      router()?.goNamed(
        AppRoutes.signInName,
        queryParameters: {'email': state.email.trim().toLowerCase()},
      );
    } on Object catch (e) {
      _handleError(e);
    }
  }

  Future<void> resendCode() async {
    try {
      showLoading();
      await _authRepository.startPasswordReset(state.email);
      showLoaded();
      showBannerSuccess(title: 'Code sent', subtitle: 'Check your inbox.');
    } on Object catch (e) {
      _handleError(e);
    }
  }

  /// The page renders `state.errorMessage` above the form, so anything the user
  /// fixes there stays inline. Everything else would otherwise be invisible on
  /// a step that has already moved on, so it snacks.
  void _handleError(Object error) {
    onError(error);

    final exception = resolveException(error);
    final rendersInline = switch (exception) {
      EmailAlreadyRegisteredException() ||
      WeakPasswordException() ||
      InvalidCodeException() ||
      EmailNotConfirmedException() ||
      InvalidCredentialsException() => true,
      _ => false,
    };

    if (!rendersInline) {
      showSnackError(msg: exception.displayMessage);
    }
  }
}
