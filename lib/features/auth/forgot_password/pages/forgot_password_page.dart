import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/auth/forgot_password/states/forgot_password_state.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/otp_field.dart';

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
              if (currentState.isError && currentState.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  currentState.errorMessage!,
                  style: context.textStyles.sansBody.copyWith(color: context.colors.red5),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(onPressed: _canSubmit ? _submit : null, child: Text(_buttonLabel)),
              if (currentState.step == ResetStep.code) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: currentState.isLoading ? null : notifier.resendCode,
                  child: const Text('Resend code'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _eyebrow => switch (currentState.step) {
    ResetStep.email => 'STEP 1 OF 3',
    ResetStep.code => 'STEP 2 OF 3',
    ResetStep.newPassword => 'STEP 3 OF 3',
  };

  String get _title => switch (currentState.step) {
    ResetStep.email => 'Reset your password',
    ResetStep.code => 'Enter your code',
    ResetStep.newPassword => 'Set a new password',
  };

  String get _subtitle => switch (currentState.step) {
    ResetStep.email => "Enter the address on your account and we'll send a code.",
    ResetStep.code => 'Sent to ${currentState.email}. It expires in 10 minutes.',
    ResetStep.newPassword => "You'll be signed out and asked to sign in with it.",
  };

  String get _buttonLabel => switch (currentState.step) {
    ResetStep.email => 'Send code',
    ResetStep.code => 'Verify code',
    ResetStep.newPassword => 'Save password',
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
            label: 'Email',
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
            label: 'New password',
            helperText: 'At least 6 characters.',
            obscureText: currentState.obscurePassword,
            onChanged: notifier.updatePassword,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Confirm new password',
            errorText: currentState.confirmPasswordError,
            obscureText: currentState.obscurePassword,
            onChanged: notifier.updateConfirmPassword,
          ),
        ];
    }
  }
}
