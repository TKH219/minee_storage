import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/auth/forgot_password/states/forgot_password_state.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/otp_field.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

class ForgotPasswordPage extends BasePage {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends BasePageState<ForgotPasswordPage, ForgotPasswordState, ForgotPasswordStateNotifier> {
  @override
  void setCurrentState() => currentState = ref.watch(forgotPasswordStateProvider);

  @override
  void setNotifier() => notifier = ref.read(forgotPasswordStateProvider.notifier);

  @override
  Widget buildPageContent(BuildContext context) {
    canPopPage = currentState.step == ResetStep.email;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (currentState.step == ResetStep.email) {
              notifier.router()?.goNamed(AppRoutes.signInName);
            } else {
              notifier.back();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _eyebrow,
                style: context.textStyles.sansTableHeader.copyWith(
                  color: context.colors.neutral6,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(_title, style: context.textStyles.sansTitleHeading1),
              const SizedBox(height: 8),
              Text(
                _subtitle,
                style: context.textStyles.sansBody.copyWith(color: context.colors.neutral6),
              ),
              const SizedBox(height: 32),
              ..._stepFields(),
              if (currentState.isError && currentState.errorMessageKey != null) ...[
                const SizedBox(height: 16),
                Text(
                  currentState.errorMessage ?? currentState.errorMessageKey!.tr(),
                  style: context.textStyles.sansBody.copyWith(color: context.colors.red5),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(onPressed: _canSubmit ? _submit : null, child: Text(_buttonLabel)),
              if (currentState.step == ResetStep.code) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: currentState.isLoading ? null : notifier.resendCode,
                  child: Text(LocaleKeys.auth_common_resendCode.tr()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _eyebrow => switch (currentState.step) {
    ResetStep.email => LocaleKeys.auth_common_step1of3.tr(),
    ResetStep.code => LocaleKeys.auth_common_step2of3.tr(),
    ResetStep.newPassword => LocaleKeys.auth_common_step3of3.tr(),
  };

  String get _title => switch (currentState.step) {
    ResetStep.email => LocaleKeys.auth_forgot_title.tr(),
    ResetStep.code => LocaleKeys.auth_common_enterYourCode.tr(),
    ResetStep.newPassword => LocaleKeys.auth_forgot_newPasswordTitle.tr(),
  };

  String get _subtitle => switch (currentState.step) {
    ResetStep.email => LocaleKeys.auth_forgot_emailHint.tr(),
    ResetStep.code => LocaleKeys.auth_common_sentTo.tr(namedArgs: {'email': currentState.email}),
    ResetStep.newPassword => LocaleKeys.auth_forgot_newPasswordHint.tr(),
  };

  String get _buttonLabel => switch (currentState.step) {
    ResetStep.email => LocaleKeys.auth_forgot_sendCode.tr(),
    ResetStep.code => LocaleKeys.auth_forgot_verifyCode.tr(),
    ResetStep.newPassword => LocaleKeys.auth_forgot_savePassword.tr(),
  };

  bool get _canSubmit => switch (currentState.step) {
    ResetStep.email => currentState.canSubmitEmail,
    ResetStep.code => currentState.canSubmitCode,
    ResetStep.newPassword => currentState.canSubmitPassword,
  };

  void _submit() {
    switch (currentState.step) {
      case ResetStep.email:
        notifier.submitEmail();
      case ResetStep.code:
        notifier.submitCode();
      case ResetStep.newPassword:
        notifier.submitNewPassword();
    }
  }

  List<Widget> _stepFields() {
    switch (currentState.step) {
      case ResetStep.email:
        return [
          AppTextField(
            label: LocaleKeys.auth_common_email.tr(),
            hint: 'you@shop.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: notifier.updateEmail,
          ),
        ];
      case ResetStep.code:
        return [
          OtpField(
            onChanged: notifier.updateCode,
            onSubmitted: (_) => notifier.submitCode(),
            hasError: currentState.isError,
          ),
        ];
      case ResetStep.newPassword:
        return [
          AppTextField(
            label: LocaleKeys.auth_forgot_newPassword.tr(),
            helperText: LocaleKeys.auth_common_minChars.tr(),
            obscureText: currentState.obscurePassword,
            onChanged: notifier.updatePassword,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: LocaleKeys.auth_forgot_confirmNewPassword.tr(),
            errorText: currentState.confirmPasswordErrorKey?.tr(),
            obscureText: currentState.obscurePassword,
            onChanged: notifier.updateConfirmPassword,
          ),
        ];
    }
  }
}
