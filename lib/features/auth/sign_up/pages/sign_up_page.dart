import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/auth/sign_up/states/sign_up_state.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/otp_field.dart';

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
                    'Your password is already set, so we skipped that step. '
                    'The shop name you just entered replaces the old one.',
                    style: context.textStyles.sansCaption.copyWith(color: context.colors.neutral7),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ..._stepFields(context),
              if (currentState.isError && currentState.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  currentState.errorMessage!,
                  style: context.textStyles.sansBody.copyWith(color: context.colors.red5),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(onPressed: _canSubmit ? _submit : null, child: Text(_buttonLabel)),
              if (currentState.step == SignUpStep.credentials) ...[
                const SizedBox(height: 12),
                _footer(
                  context,
                  prompt: 'Already have an account? ',
                  action: 'Sign in',
                  onTap: () => notifier.router()?.goNamed(AppRoutes.signInName),
                ),
              ],
              if (currentState.step == SignUpStep.code) ...[
                const SizedBox(height: 12),
                _footer(
                  context,
                  prompt: "Didn't get it? ",
                  action: 'Resend code',
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
    if (currentState.wasResumed) return 'STEP 2 OF 2 · RESUMED';
    return switch (currentState.step) {
      SignUpStep.credentials => 'STEP 1 OF 3',
      SignUpStep.password => 'STEP 2 OF 3',
      SignUpStep.code => 'STEP 3 OF 3',
    };
  }

  String get _title {
    if (currentState.wasResumed && currentState.step == SignUpStep.code) {
      return 'Finish signing up';
    }
    return switch (currentState.step) {
      SignUpStep.credentials => 'Create your account',
      SignUpStep.password => 'Choose a password',
      SignUpStep.code => 'Enter your code',
    };
  }

  String get _subtitle {
    if (currentState.wasResumed && currentState.step == SignUpStep.code) {
      return 'You started this before. Enter the new code we just sent.';
    }
    return switch (currentState.step) {
      SignUpStep.credentials => "We'll email you an 8-digit code to confirm it.",
      SignUpStep.password => "You'll use this with ${currentState.email} to sign in.",
      SignUpStep.code => 'Sent to ${currentState.email}. It expires in 10 minutes.',
    };
  }

  String get _buttonLabel => switch (currentState.step) {
    SignUpStep.credentials => 'Continue',
    SignUpStep.password => 'Create account',
    SignUpStep.code => 'Confirm account',
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
            label: 'Email',
            hint: 'you@shop.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: notifier.updateEmail,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Shop name',
            hint: 'Northside Grocers',
            helperText: 'Shown on your account. You can change it later.',
            onChanged: notifier.updateShopName,
          ),
        ];
      case SignUpStep.password:
        return [
          AppTextField(
            label: 'Password',
            helperText: 'At least 6 characters.',
            obscureText: currentState.obscurePassword,
            onChanged: notifier.updatePassword,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Confirm password',
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
