import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/auth/sign_in/states/sign_in_state.dart';
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
    return Scaffold(
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
                'Sign in to continue to Mine Storage.',
                style: context.textStyles.sansBody.copyWith(
                  color: context.colors.neutral6,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
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
                onSubmitted: (_) => notifier.signIn(),
              ),
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
                child: const Text('Sign in'),
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
