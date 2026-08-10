import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/extensions/string_extensions.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/features/auth/widgets/otp_field.dart';
import 'package:mine_storage/providers.dart';

enum SignUpStep { credentials, password, code }

final signUpStateProvider = AutoDisposeNotifierProvider<SignUpStateNotifier, SignUpState>(
  SignUpStateNotifier.new,
);

class SignUpState extends BaseState with Equatable {
  const SignUpState({
    this.step = SignUpStep.credentials,
    this.email = '',
    this.shopName = '',
    this.password = '',
    this.code = '',
    this.obscurePassword = true,
    this.wasResumed = false,
    super.status,
    super.errorMessage,
  });

  final SignUpStep step;
  final String email;
  final String shopName;
  final String password;
  final String code;
  final bool obscurePassword;

  /// True when the account already existed unconfirmed. The trigger wrote the
  /// row from the first attempt, so the shop name must be written over it.
  final bool wasResumed;

  bool get canSubmitCredentials =>
      email.isNotBlank && email.contains('@') && shopName.isNotBlank && !isLoading;

  bool get canSubmitPassword => password.trim().length >= 6 && !isLoading;

  bool get canSubmitCode => code.trim().length == OtpField.codeLength && !isLoading;

  @override
  SignUpState copyWith({
    StateLifeCycle? status,
    String? errorMessage,
    SignUpStep? step,
    String? email,
    String? shopName,
    String? password,
    String? code,
    bool? obscurePassword,
    bool? wasResumed,
  }) {
    return SignUpState(
      step: step ?? this.step,
      email: email ?? this.email,
      shopName: shopName ?? this.shopName,
      password: password ?? this.password,
      code: code ?? this.code,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      wasResumed: wasResumed ?? this.wasResumed,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    step,
    email,
    shopName,
    password,
    code,
    obscurePassword,
    wasResumed,
    status,
    errorMessage,
  ];
}

class SignUpStateNotifier extends BaseStateNotifier<SignUpState> {
  late final AuthRepository _authRepository;

  @override
  SignUpState createInitialState() {
    _authRepository = ref.read(authRepositoryProvider);
    return const SignUpState();
  }

  void updateEmail(String value) => updateState(state.copyWith(email: value));

  void updateShopName(String value) => updateState(state.copyWith(shopName: value));

  void updatePassword(String value) => updateState(state.copyWith(password: value));

  void updateCode(String value) => updateState(state.copyWith(code: value));

  void togglePasswordVisibility() =>
      updateState(state.copyWith(obscurePassword: !state.obscurePassword));

  void back() {
    final previous = switch (state.step) {
      SignUpStep.code => state.wasResumed ? SignUpStep.credentials : SignUpStep.password,
      SignUpStep.password => SignUpStep.credentials,
      SignUpStep.credentials => SignUpStep.credentials,
    };
    updateState(state.copyWith(step: previous, status: StateLifeCycle.init));
  }

  Future<void> submitCredentials() async {
    if (!state.canSubmitCredentials) {
      showSnackError(msg: 'Enter a valid email and your shop name.');
      return;
    }

    try {
      showLoading();
      final status = await _authRepository.checkEmail(state.email);

      switch (status) {
        case EmailStatus.confirmed:
          updateState(
            state.copyWith(
              status: StateLifeCycle.error,
              errorMessage: 'That email is already registered. Sign in instead.',
            ),
          );
        case EmailStatus.unconfirmed:
          // The account exists but was abandoned before confirmation. Resending
          // needs no password, so the user is not asked for one again.
          await _authRepository.resendSignUpCode(state.email);
          showLoaded();
          updateState(state.copyWith(step: SignUpStep.code, wasResumed: true));
        case EmailStatus.none:
          showLoaded();
          updateState(state.copyWith(step: SignUpStep.password, wasResumed: false));
      }
    } on Object catch (e) {
      _handleError(e);
    }
  }

  Future<void> submitPassword() async {
    if (!state.canSubmitPassword) {
      showSnackError(msg: 'Password must be at least 6 characters.');
      return;
    }

    try {
      showLoading();
      await _authRepository.startSignUp(
        email: state.email,
        password: state.password,
        shopName: state.shopName,
      );
      showLoaded();
      updateState(state.copyWith(step: SignUpStep.code));
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
      await _authRepository.confirmSignUp(
        email: state.email,
        token: state.code,
        shopName: state.shopName,
        wasResumed: state.wasResumed,
      );
      showLoaded();
      router()?.goNamed(AppRoutes.homeName);
    } on Object catch (e) {
      _handleError(e);
    }
  }

  Future<void> resendCode() async {
    try {
      showLoading();
      await _authRepository.resendSignUpCode(state.email);
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
