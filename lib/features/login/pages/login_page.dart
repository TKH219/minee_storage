import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/login/states/login_state.dart';
import 'package:mine_storage/shared/ui/theme_mode_button.dart';

class LoginPage extends BasePage {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends BasePageState<LoginPage, LoginState, LoginStateNotifier> {
  @override
  void setCurrentState() => currentState = ref.watch(loginStateProvider);

  @override
  void setNotifier() => notifier = ref.read(loginStateProvider.notifier);

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
                style: context.textStyles.sansBody.copyWith(color: context.colors.neutral6),
              ),
              const SizedBox(height: 32),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'your.name',
                ),
                textInputAction: TextInputAction.next,
                autocorrect: false,
                onChanged: notifier.updateUsername,
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
                onSubmitted: (_) => notifier.login(),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: currentState.canSubmit ? notifier.login : null,
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
