import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/extensions/string_extensions.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/shared/ui/otp_field.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

enum SignUpStep { credentials, code }

final signUpStateProvider = NotifierProvider<SignUpStateNotifier, SignUpState>(
  SignUpStateNotifier.new,
  isAutoDispose: true,
);

class SignUpState extends BaseState with Equatable {
  const SignUpState({
    this.step = SignUpStep.credentials,
    this.email = '',
    this.password = '',
    this.code = '',
    this.obscurePassword = true,
    this.wasResumed = false,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final SignUpStep step;
  final String email;
  final String password;
  final String code;
  final bool obscurePassword;

  /// True when the account already existed unconfirmed. The trigger wrote the
  /// row from the first attempt, so the shop name must be written over it.
  final bool wasResumed;

  bool get canSubmitCredentials =>
      email.isNotBlank && email.contains('@') && password.trim().length >= 6 && !isLoading;

  bool get canSubmitCode => code.trim().length == OtpField.codeLength && !isLoading;

  @override
  SignUpState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    SignUpStep? step,
    String? email,
    String? password,
    String? code,
    bool? obscurePassword,
    bool? wasResumed,
  }) {
    return SignUpState(
      step: step ?? this.step,
      email: email ?? this.email,
      password: password ?? this.password,
      code: code ?? this.code,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      wasResumed: wasResumed ?? this.wasResumed,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    step,
    email,
    password,
    code,
    obscurePassword,
    wasResumed,
    status,
    errorMessageKey, errorMessage,
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

  void updatePassword(String value) => updateState(state.copyWith(password: value));

  /// The rejected-code error clears the moment a digit changes — it must not
  /// sit there while the user is correcting it.
  void updateCode(String value) =>
      updateState(state.copyWith(code: value, status: StateLifeCycle.init));

  @visibleForTesting
  void goToStep(SignUpStep step) => updateState(state.copyWith(step: step));

  @visibleForTesting
  void markResumed() => updateState(state.copyWith(wasResumed: true));

  @visibleForTesting
  void rejectCode(String message) =>
      updateState(state.copyWith(status: StateLifeCycle.error, errorMessageKey: message));

  void togglePasswordVisibility() =>
      updateState(state.copyWith(obscurePassword: !state.obscurePassword));

  void back() {
    updateState(state.copyWith(step: SignUpStep.credentials, status: StateLifeCycle.init));
  }

  Future<void> submitCredentials() async {
    if (!state.canSubmitCredentials) {
      showSnackError(msg: LocaleKeys.auth_signUp_invalidEmailOrPassword);
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
              errorMessageKey: LocaleKeys.auth_signUp_emailRegistered,
            ),
          );
        case EmailStatus.unconfirmed:
          // The account exists but was abandoned before confirmation. Resending
          // needs no password, so the user is not asked for one again.
          await _authRepository.resendSignUpCode(state.email);
          showLoaded();
          updateState(state.copyWith(step: SignUpStep.code, wasResumed: true));
        case EmailStatus.none:
          await _authRepository.startSignUp(
            email: state.email,
            password: state.password,
            shopName: '',
          );
          showLoaded();
          updateState(state.copyWith(step: SignUpStep.code, wasResumed: false));
      }
    } on Object catch (e) {
      _handleError(e);
    }
  }

  Future<void> submitCode() async {
    if (!state.canSubmitCode) {
      showSnackError(msg: LocaleKeys.auth_common_enterCode);
      return;
    }

    try {
      showLoading();
      await _authRepository.confirmSignUp(
        email: state.email,
        token: state.code,
        shopName: '',
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
      showBannerSuccess(title: LocaleKeys.auth_common_codeSentTitle.tr(), subtitle: LocaleKeys.auth_common_codeSentSubtitle.tr());
    } on Object catch (e) {
      _handleError(e);
    }
  }

  /// The page renders `state.errorMessageKey` above the form, so anything the user
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
      showSnackError(msg: exception.message ?? exception.messageKey.tr());
    }
  }
}
