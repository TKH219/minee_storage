import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/features/auth/forgot_password/states/forgot_password_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/auth_test_harness.dart';
import '../../support/fake_auth_repository.dart';

import '../../support/localization_test_harness.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

void main() {
  setUp(useLocale);

  ({ProviderContainer container, FakeAuthRepository repository, GoRouter router}) build({
    EmailStatus status = EmailStatus.confirmed,
  }) {
    final router = buildTestRouter();
    final repository = FakeAuthRepository(emailStatus: status);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        routerProvider.overrideWithValue(router),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, repository: repository, router: router);
  }

  test('a known email sends a code and advances', () async {
    final t = build();
    final notifier = t.container.read(forgotPasswordStateProvider.notifier)
      ..updateEmail('a@b.com');

    await notifier.submitEmail();

    expect(t.container.read(forgotPasswordStateProvider).step, ResetStep.code);
    expect(t.repository.calls, contains('startPasswordReset:a@b.com'));
  });

  test('an unknown email is refused before any email is sent', () async {
    final t = build(status: EmailStatus.none);
    final notifier = t.container.read(forgotPasswordStateProvider.notifier)
      ..updateEmail('nobody@example.com');

    await notifier.submitEmail();

    final state = t.container.read(forgotPasswordStateProvider);
    expect(state.step, ResetStep.email);
    expect(state.errorMessageKey, LocaleKeys.auth_forgot_noAccount);
    expect(
      t.repository.calls.where((c) => c.startsWith('startPasswordReset')),
      isEmpty,
    );
  });

  test('a valid code advances to the new-password step', () async {
    final t = build();
    final notifier = t.container.read(forgotPasswordStateProvider.notifier)
      ..updateEmail('a@b.com');
    await notifier.submitEmail();

    notifier.updateCode('12345678');
    await notifier.submitCode();

    expect(
      t.container.read(forgotPasswordStateProvider).step,
      ResetStep.newPassword,
    );
    expect(t.repository.calls, contains('verifyPasswordResetCode:12345678'));
  });

  test('setting the password returns to sign-in with the email prefilled', () async {
    final t = build();
    final notifier = t.container.read(forgotPasswordStateProvider.notifier)
      ..updateEmail('a@b.com');
    await notifier.submitEmail();
    notifier.updateCode('12345678');
    await notifier.submitCode();

    notifier
      ..updatePassword('brand-new')
      ..updateConfirmPassword('brand-new');
    await notifier.submitNewPassword();

    expect(t.repository.calls, contains('setNewPassword'));
    expect(currentPath(t.router), '/sign-in');
  });

  test('the new password must be at least six characters', () async {
    final t = build();
    final notifier = t.container.read(forgotPasswordStateProvider.notifier)
      ..updateEmail('a@b.com');
    await notifier.submitEmail();
    notifier.updateCode('12345678');
    await notifier.submitCode();

    notifier.updatePassword('12345');
    await notifier.submitNewPassword();

    expect(t.repository.calls.where((c) => c == 'setNewPassword'), isEmpty);
  });
}
