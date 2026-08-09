import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/auth/forgot_password/states/forgot_password_state.dart';
import 'package:mine_storage/features/auth/widgets/otp_field.dart';

class ForgotPasswordPage extends BasePage {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends
        BasePageState<
          ForgotPasswordPage,
          ForgotPasswordState,
          ForgotPasswordStateNotifier
        > {
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
              Text(_title, style: context.textStyles.sansTitleHeading1),
              const SizedBox(height: 8),
              Text(
                _subtitle,
                style: context.textStyles.sansBody.copyWith(
                  color: context.colors.neutral6,
                ),
              ),
              const SizedBox(height: 32),
              ..._stepFields(),
              if (currentState.isError && currentState.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  currentState.errorMessage!,
                  style: context.textStyles.sansBody.copyWith(
                    color: context.colors.red5,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _canSubmit ? _submit : null,
                child: Text(_buttonLabel),
              ),
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

  String get _title => switch (currentState.step) {
    ResetStep.email => 'Reset your password',
    ResetStep.code => 'Check your email',
    ResetStep.newPassword => 'Set a new password',
  };

  String get _subtitle => switch (currentState.step) {
    ResetStep.email => 'We will send a code to your email.',
    ResetStep.code => 'We sent an 8-digit code to ${currentState.email}.',
    ResetStep.newPassword => 'At least 6 characters.',
  };

  String get _buttonLabel => switch (currentState.step) {
    ResetStep.email => 'Send code',
    ResetStep.code => 'Verify',
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
          TextField(
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@shop.com',
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onChanged: notifier.updateEmail,
            onSubmitted: (_) => notifier.submitEmail(),
          ),
        ];
      case ResetStep.code:
        return [
          OtpField(
            onChanged: notifier.updateCode,
            onSubmitted: (_) => notifier.submitCode(),
          ),
        ];
      case ResetStep.newPassword:
        return [
          TextField(
            decoration: InputDecoration(
              labelText: 'New password',
              suffixIcon: IconButton(
                icon: Icon(
                  currentState.obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
                onPressed: notifier.togglePasswordVisibility,
              ),
            ),
            obscureText: currentState.obscurePassword,
            textInputAction: TextInputAction.done,
            onChanged: notifier.updatePassword,
            onSubmitted: (_) => notifier.submitNewPassword(),
          ),
        ];
    }
  }
}
