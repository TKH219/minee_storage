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

  test('a free email advances to the password step', () async {
    final t = build();
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updateShopName('Minee Storage');

    await notifier.submitCredentials();

    expect(t.container.read(signUpStateProvider).step, SignUpStep.password);
    expect(t.container.read(signUpStateProvider).wasResumed, isFalse);
  });

  test('a confirmed email is blocked and stays on step one', () async {
    final t = build(status: EmailStatus.confirmed);
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updateShopName('Minee Storage');

    await notifier.submitCredentials();

    final state = t.container.read(signUpStateProvider);
    expect(state.step, SignUpStep.credentials);
    expect(state.errorMessageKey, LocaleKeys.auth_signUp_emailRegistered);
  });

  test('an unconfirmed email resends and jumps straight to the code step', () async {
    final t = build(status: EmailStatus.unconfirmed);
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updateShopName('New Name');

    await notifier.submitCredentials();

    final state = t.container.read(signUpStateProvider);
    expect(state.step, SignUpStep.code);
    expect(state.wasResumed, isTrue);
    expect(t.repository.calls, contains('resendSignUpCode:a@b.com'));
  });

  test('the password step requires at least six characters', () async {
    final t = build();
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updateShopName('Minee Storage');
    await notifier.submitCredentials();

    notifier.updatePassword('12345');
    await notifier.submitPassword();

    expect(t.container.read(signUpStateProvider).step, SignUpStep.password);
    expect(t.repository.calls.where((c) => c.startsWith('startSignUp')), isEmpty);
  });

  test('a valid password signs up and advances to the code step', () async {
    final t = build();
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updateShopName('Minee Storage');
    await notifier.submitCredentials();

    notifier.updatePassword('secret1');
    await notifier.submitPassword();

    expect(t.container.read(signUpStateProvider).step, SignUpStep.code);
    expect(t.repository.calls, contains('startSignUp:a@b.com:Minee Storage'));
  });

  test('a valid code confirms and navigates home', () async {
    final t = build();
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updateShopName('Minee Storage');
    await notifier.submitCredentials();
    notifier.updatePassword('secret1');
    await notifier.submitPassword();

    notifier.updateCode('123456');
    await notifier.submitCode();

    expect(t.repository.calls, contains('confirmSignUp:123456:resumed=false'));
    expect(currentPath(t.router), '/home');
  });

  test('the code step rejects anything other than six digits', () async {
    final t = build();
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updateShopName('Minee Storage');
    await notifier.submitCredentials();
    notifier.updatePassword('secret1');
    await notifier.submitPassword();

    notifier.updateCode('1234');
    await notifier.submitCode();

    expect(t.repository.calls.where((c) => c.startsWith('confirmSignUp')), isEmpty);
  });

  test('back steps within the flow', () async {
    final t = build();
    final notifier = t.container.read(signUpStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updateShopName('Minee Storage');
    await notifier.submitCredentials();

    notifier.back();

    expect(t.container.read(signUpStateProvider).step, SignUpStep.credentials);
  });
}
