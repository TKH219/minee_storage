import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/auth/sign_in/states/sign_in_state.dart';
import 'package:mine_storage/features/auth/widgets/auth_error_banner.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';
import 'package:mine_storage/shared/ui/theme_mode_button.dart';

class SignInPage extends BasePage {
  const SignInPage({super.key, this.prefilledEmail});

  final String? prefilledEmail;

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends BasePageState<SignInPage, SignInState, SignInStateNotifier> {
  late final TextEditingController _emailController = TextEditingController(
    text: widget.prefilledEmail ?? '',
  );

  @override
  void initState() {
    // The design holds progress inside the Sign in button so the row never
    // jumps under the thumb; the shared full-bleed overlay would hide it.
    allowToShowLoading = false;
    super.initState();
  }

  @override
  void initDataFromConstructor() {
    final email = widget.prefilledEmail;
    if (email != null && email.isNotEmpty) {
      notifier.prefillEmail(email);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  void setCurrentState() => currentState = ref.watch(signInStateProvider);

  @override
  void setNotifier() => notifier = ref.read(signInStateProvider.notifier);

  @override
  Widget buildPageContent(BuildContext context) {
    final placement = currentState.errorPlacement;
    final message = currentState.errorMessage;
    final showBanner = placement != AuthErrorPlacement.none && message != null;

    return Scaffold(
      backgroundColor: context.colors.neutral0,
      appBar: AppBar(actions: const [ThemeModeButton()]),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Welcome back', style: context.textStyles.sansTitleHeading1),
              const SizedBox(height: 8),
              Text(
                'Sign in to pick up where your stock left off.',
                style: context.textStyles.sansBody.copyWith(color: context.colors.neutral6),
              ),
              if (showBanner && placement == AuthErrorPlacement.aboveEmail) ...[
                const SizedBox(height: 20),
                AuthErrorBanner(message: message),
              ],
              const SizedBox(height: 32),
              AppTextField(
                label: 'Email',
                hint: 'you@shop.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: notifier.updateEmail,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password',
                hint: 'Your password',
                obscureText: currentState.obscurePassword,
                onChanged: notifier.updatePassword,
              ),
              if (showBanner && placement == AuthErrorPlacement.belowPassword) ...[
                const SizedBox(height: 12),
                AuthErrorBanner(message: message),
              ],
              if (placement != AuthErrorPlacement.aboveEmail)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        notifier.router()?.goNamed(AppRoutes.forgotPasswordName),
                    child: const Text('Forgot password?'),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: currentState.canSubmit ? notifier.signIn : null,
                child: currentState.isLoading
                    ? const ButtonDots()
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => notifier.router()?.goNamed(AppRoutes.signUpName),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
