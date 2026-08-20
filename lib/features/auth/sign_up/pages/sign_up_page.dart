import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/auth/sign_up/states/sign_up_state.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/otp_field.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

class SignUpPage extends BasePage {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends BasePageState<SignUpPage, SignUpState, SignUpStateNotifier> {
  @override
  void setCurrentState() => currentState = ref.watch(signUpStateProvider);

  @override
  void setNotifier() => notifier = ref.read(signUpStateProvider.notifier);

  @override
  Widget buildPageContent(BuildContext context) {
    // Back moves between steps, not out of the flow, until step one.
    canPopPage = currentState.step == SignUpStep.credentials;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (currentState.step == SignUpStep.credentials) {
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
              if (currentState.wasResumed && currentState.step == SignUpStep.code) ...[
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: context.colors.tintPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text(
                    LocaleKeys.auth_signUp_resumedNotice.tr(),
                    style: context.textStyles.sansCaption.copyWith(color: context.colors.neutral7),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ..._stepFields(context),
              if (currentState.isError && currentState.errorMessageKey != null) ...[
                const SizedBox(height: 16),
                Text(
                  currentState.errorMessage ?? currentState.errorMessageKey!.tr(),
                  style: context.textStyles.sansBody.copyWith(color: context.colors.red5),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(onPressed: _canSubmit ? _submit : null, child: Text(_buttonLabel)),
              if (currentState.step == SignUpStep.credentials) ...[
                const SizedBox(height: 12),
                _footer(
                  context,
                  prompt: LocaleKeys.auth_signUp_haveAccount.tr(),
                  action: LocaleKeys.auth_signUp_signIn.tr(),
                  onTap: () => notifier.router()?.goNamed(AppRoutes.signInName),
                ),
              ],
              if (currentState.step == SignUpStep.code) ...[
                const SizedBox(height: 12),
                _footer(
                  context,
                  prompt: LocaleKeys.auth_common_didntGetIt.tr(),
                  action: LocaleKeys.auth_common_resendCode.tr(),
                  onTap: currentState.isLoading ? null : notifier.resendCode,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// A resumed signup skips the password step entirely, so it counts two.
  String get _eyebrow {
    if (currentState.wasResumed) return LocaleKeys.auth_signUp_step2of2Resumed.tr();
    return switch (currentState.step) {
      SignUpStep.credentials => LocaleKeys.auth_common_step1of3.tr(),
      SignUpStep.password => LocaleKeys.auth_common_step2of3.tr(),
      SignUpStep.code => LocaleKeys.auth_common_step3of3.tr(),
    };
  }

  String get _title {
    if (currentState.wasResumed && currentState.step == SignUpStep.code) {
      return LocaleKeys.auth_signUp_finishSigningUp.tr();
    }
    return switch (currentState.step) {
      SignUpStep.credentials => LocaleKeys.auth_signUp_title.tr(),
      SignUpStep.password => LocaleKeys.auth_signUp_choosePassword.tr(),
      SignUpStep.code => LocaleKeys.auth_common_enterYourCode.tr(),
    };
  }

  String get _subtitle {
    if (currentState.wasResumed && currentState.step == SignUpStep.code) {
      return LocaleKeys.auth_signUp_resumedHint.tr();
    }
    return switch (currentState.step) {
      SignUpStep.credentials => LocaleKeys.auth_signUp_credentialsHint.tr(),
      SignUpStep.password => LocaleKeys.auth_signUp_passwordHint.tr(namedArgs: {'email': currentState.email}),
      SignUpStep.code => LocaleKeys.auth_common_sentTo.tr(namedArgs: {'email': currentState.email}),
    };
  }

  String get _buttonLabel => switch (currentState.step) {
    SignUpStep.credentials => LocaleKeys.auth_signUp_continueLabel.tr(),
    SignUpStep.password => LocaleKeys.auth_signUp_createAccount.tr(),
    SignUpStep.code => LocaleKeys.auth_signUp_confirmAccount.tr(),
  };

  bool get _canSubmit => switch (currentState.step) {
    SignUpStep.credentials => currentState.canSubmitCredentials,
    SignUpStep.password => currentState.canSubmitPassword,
    SignUpStep.code => currentState.canSubmitCode,
  };

  void _submit() {
    switch (currentState.step) {
      case SignUpStep.credentials:
        notifier.submitCredentials();
      case SignUpStep.password:
        notifier.submitPassword();
      case SignUpStep.code:
        notifier.submitCode();
    }
  }

  Widget _footer(
    BuildContext context, {
    required String prompt,
    required String action,
    required VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prompt, style: context.textStyles.sansBody.copyWith(color: context.colors.neutral6)),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: context.textStyles.sansBodyBold.copyWith(color: context.colors.inkPrimary),
          ),
        ),
      ],
    );
  }

  List<Widget> _stepFields(BuildContext context) {
    switch (currentState.step) {
      case SignUpStep.credentials:
        return [
          AppTextField(
            label: LocaleKeys.auth_common_email.tr(),
            hint: 'you@shop.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: notifier.updateEmail,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: LocaleKeys.auth_signUp_shopName.tr(),
            hint: LocaleKeys.auth_signUp_shopNameHint.tr(),
            helperText: LocaleKeys.auth_signUp_shopNameHelp.tr(),
            onChanged: notifier.updateShopName,
          ),
        ];
      case SignUpStep.password:
        return [
          AppTextField(
            label: LocaleKeys.auth_common_password.tr(),
            helperText: LocaleKeys.auth_common_minChars.tr(),
            obscureText: currentState.obscurePassword,
            onChanged: notifier.updatePassword,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: LocaleKeys.auth_signUp_confirmPassword.tr(),
            obscureText: currentState.obscurePassword,
            onChanged: notifier.updatePassword,
          ),
        ];
      case SignUpStep.code:
        return [
          OtpField(
            onChanged: notifier.updateCode,
            onSubmitted: (_) => notifier.submitCode(),
            hasError: currentState.isError,
          ),
        ];
    }
  }
}
