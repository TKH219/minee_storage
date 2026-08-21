import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/features/auth/sign_up/states/sign_up_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/auth_test_harness.dart';
import '../../support/fake_auth_repository.dart';

import '../../support/localization_test_harness.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

void main() {
  setUp(useLocale);

  ({ProviderContainer container, FakeAuthRepository repository, GoRouter router}) build({
    EmailStatus status = EmailStatus.none,
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

  test('valid credentials sign up and advance to the code step', () async {
    final t = build();
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updatePassword('secret1');

    await notifier.submitCredentials();

    expect(t.container.read(signUpStateProvider).step, SignUpStep.code);
    expect(t.container.read(signUpStateProvider).wasResumed, isFalse);
    expect(t.repository.calls, contains('startSignUp:a@b.com:'));
  });

  test('a confirmed email is blocked and stays on step one', () async {
    final t = build(status: EmailStatus.confirmed);
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updatePassword('secret1');

    await notifier.submitCredentials();

    final state = t.container.read(signUpStateProvider);
    expect(state.step, SignUpStep.credentials);
    expect(state.errorMessageKey, LocaleKeys.auth_signUp_emailRegistered);
    expect(t.repository.calls.where((c) => c.startsWith('startSignUp')), isEmpty);
  });

  test('an unconfirmed email resends and jumps straight to the code step', () async {
    final t = build(status: EmailStatus.unconfirmed);
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updatePassword('secret1');

    await notifier.submitCredentials();

    final state = t.container.read(signUpStateProvider);
    expect(state.step, SignUpStep.code);
    expect(state.wasResumed, isTrue);
    expect(t.repository.calls, contains('resendSignUpCode:a@b.com'));
    expect(t.repository.calls.where((c) => c.startsWith('startSignUp')), isEmpty);
  });

  test('a password under six characters never reaches the repository', () async {
    final t = build();
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updatePassword('12345');

    await notifier.submitCredentials();

    expect(t.container.read(signUpStateProvider).step, SignUpStep.credentials);
    expect(t.repository.calls, isEmpty);
  });

  test('an email without an at sign never reaches the repository', () async {
    final t = build();
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('nope')
      ..updatePassword('secret1');

    await notifier.submitCredentials();

    expect(t.container.read(signUpStateProvider).step, SignUpStep.credentials);
    expect(t.repository.calls, isEmpty);
  });

  test('a valid code confirms and navigates onward', () async {
    final t = build();
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updatePassword('secret1');
    await notifier.submitCredentials();

    notifier.updateCode('123456');
    await notifier.submitCode();

    expect(t.repository.calls, contains('confirmSignUp:123456:resumed=false'));
    expect(currentPath(t.router), '/home');
  });

  test('the code step rejects anything other than six digits', () async {
    final t = build();
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updatePassword('secret1');
    await notifier.submitCredentials();

    notifier.updateCode('1234');
    await notifier.submitCode();

    expect(t.repository.calls.where((c) => c.startsWith('confirmSignUp')), isEmpty);
  });

  test('back returns from the code step to credentials', () async {
    final t = build();
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updatePassword('secret1');
    await notifier.submitCredentials();

    notifier.back();

    expect(t.container.read(signUpStateProvider).step, SignUpStep.credentials);
  });
}
