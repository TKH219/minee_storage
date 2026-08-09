import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/auth/sign_up/states/sign_up_state.dart';
import 'package:mine_storage/features/auth/widgets/otp_field.dart';

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
              Text(_title, style: context.textStyles.sansTitleHeading1),
              const SizedBox(height: 8),
              Text(
                _subtitle,
                style: context.textStyles.sansBody.copyWith(
                  color: context.colors.neutral6,
                ),
              ),
              const SizedBox(height: 32),
              ..._stepFields(context),
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
              if (currentState.step == SignUpStep.code) ...[
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
    SignUpStep.credentials => 'Create your account',
    SignUpStep.password => 'Choose a password',
    SignUpStep.code => 'Check your email',
  };

  String get _subtitle => switch (currentState.step) {
    SignUpStep.credentials => 'Tell us your email and what your shop is called.',
    SignUpStep.password => 'At least 6 characters.',
    SignUpStep.code => 'We sent an 8-digit code to ${currentState.email}.',
  };

  String get _buttonLabel => switch (currentState.step) {
    SignUpStep.credentials => 'Continue',
    SignUpStep.password => 'Create account',
    SignUpStep.code => 'Verify',
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

  List<Widget> _stepFields(BuildContext context) {
    switch (currentState.step) {
      case SignUpStep.credentials:
        return [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@shop.com',
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            onChanged: notifier.updateEmail,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Shop name',
              hintText: 'Minee Storage',
            ),
            textInputAction: TextInputAction.done,
            onChanged: notifier.updateShopName,
          ),
        ];
      case SignUpStep.password:
        return [
          TextField(
            decoration: InputDecoration(
              labelText: 'Password',
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
            onSubmitted: (_) => notifier.submitPassword(),
          ),
        ];
      case SignUpStep.code:
        return [
          OtpField(
            onChanged: notifier.updateCode,
            onSubmitted: (_) => notifier.submitCode(),
          ),
        ];
    }
  }
}
