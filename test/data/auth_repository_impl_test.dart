import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/repositories/auth_repository_impl.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';

import 'package:mine_storage/data/models/models.dart';

import '../support/fake_auth_data_source.dart';
import '../support/model_fixtures.dart';

import '../support/localization_test_harness.dart';

UserModel row({bool deactivated = false, String shop = 'Minee'}) =>
    userModelFixture(fullName: shop, isDeactivated: deactivated);

void main() {
  setUp(useLocale);

  test('signIn returns the user and stamps last_signed_in_at', () async {
    final source = FakeAuthDataSource(row: row());
    final repository = AuthRepositoryImpl(source, source);

    final user = await repository.signIn(email: 'A@B.com ', password: 'secret');

    expect(user.id, 'uid-1');
    expect(user.fullName, 'Minee');
    expect(source.calls, contains('signIn:a@b.com'));
    expect(source.calls, contains('touch:uid-1'));
  });

  test('signIn refuses a deactivated user and signs them out', () async {
    final source = FakeAuthDataSource(row: row(deactivated: true));
    final repository = AuthRepositoryImpl(source, source);

    await expectLater(
      () => repository.signIn(email: 'a@b.com', password: 'secret'),
      throwsA(
        isA<ForbiddenException>().having(
          (e) => e.message,
          'message',
          'This account has been deactivated. Contact support to get it reopened.',
        ),
      ),
    );
    expect(source.calls, contains('signOut'));
  });

  test('signIn survives a failing last_signed_in_at stamp', () async {
    final source = FakeAuthDataSource(
      row: row(),
      touchError: const ServerException(message: 'nope'),
    );
    final repository = AuthRepositoryImpl(source, source);

    final user = await repository.signIn(email: 'a@b.com', password: 'secret');

    expect(user.id, 'uid-1');
  });

  test('signIn maps invalid credentials', () async {
    final source = FakeAuthDataSource(
      signInError: const AuthException('Invalid login credentials'),
    );
    final repository = AuthRepositoryImpl(source, source);

    await expectLater(
      () => repository.signIn(email: 'a@b.com', password: 'wrong'),
      throwsA(isA<InvalidCredentialsException>()),
    );
  });

  test('signIn throws when the users row is missing', () async {
    final source = FakeAuthDataSource(row: null);
    final repository = AuthRepositoryImpl(source, source);

    await expectLater(
      () => repository.signIn(email: 'a@b.com', password: 'secret'),
      throwsA(isA<AppException>()),
    );
  });

  test('checkEmail maps each rpc string to EmailStatus', () async {
    for (final entry in {
      'none': EmailStatus.none,
      'unconfirmed': EmailStatus.unconfirmed,
      'confirmed': EmailStatus.confirmed,
    }.entries) {
      final source = FakeAuthDataSource(status: entry.key);
      final repository = AuthRepositoryImpl(source, source);

      expect(await repository.checkEmail('a@b.com'), entry.value);
    }
  });

  test('checkEmail treats an unrecognised rpc value as none', () async {
    final source = FakeAuthDataSource(status: 'weird');
    final repository = AuthRepositoryImpl(source, source);

    expect(await repository.checkEmail('a@b.com'), EmailStatus.none);
  });

  test('startSignUp forwards a normalised email', () async {
    final source = FakeAuthDataSource();
    final repository = AuthRepositoryImpl(source, source);

    await repository.startSignUp(email: ' A@B.com ', password: 'secret');

    expect(source.calls, contains('signUp:a@b.com'));
  });

  test('confirmSignUp returns the profile row the trigger created', () async {
    final source = FakeAuthDataSource(row: row(shop: 'Original'));
    final repository = AuthRepositoryImpl(source, source);

    final user = await repository.confirmSignUp(email: 'a@b.com', token: '123456');

    expect(user.fullName, 'Original');
    expect(source.calls.where((c) => c.startsWith('updateProfileRow')), isEmpty);
  });

  test('confirmSignUp maps a bad code', () async {
    final source = FakeAuthDataSource(
      verifyError: const AuthException('Token has expired or is invalid'),
    );
    final repository = AuthRepositoryImpl(source, source);

    await expectLater(
      () => repository.confirmSignUp(email: 'a@b.com', token: '00000000'),
      throwsA(isA<InvalidCodeException>()),
    );
  });

  test('startPasswordReset sends to a normalised email', () async {
    final source = FakeAuthDataSource();
    final repository = AuthRepositoryImpl(source, source);

    await repository.startPasswordReset(' A@B.com ');

    expect(source.calls, contains('reset:a@b.com'));
  });

  test('verifyPasswordResetCode maps an expired code', () async {
    final source = FakeAuthDataSource(
      verifyError: const AuthException('Token has expired or is invalid'),
    );
    final repository = AuthRepositoryImpl(source, source);

    await expectLater(
      () => repository.verifyPasswordResetCode(email: 'a@b.com', token: '00000000'),
      throwsA(isA<InvalidCodeException>()),
    );
  });

  test('setNewPassword updates then signs out, in that order', () async {
    final source = FakeAuthDataSource();
    final repository = AuthRepositoryImpl(source, source);

    await repository.setNewPassword('brand-new');

    expect(source.lastPassword, 'brand-new');
    expect(
      source.calls.indexOf('updatePassword') < source.calls.indexOf('signOut'),
      isTrue,
    );
  });

  test('updateProfile writes a trimmed name and returns the refreshed user', () async {
    final source = FakeAuthDataSource(row: row(shop: 'Linh Nguyen'));
    final repository = AuthRepositoryImpl(source, source);

    final user = await repository.updateProfile(fullName: '  Linh Nguyen  ');

    expect(source.calls, contains('updateProfileRow:uid-1:Linh Nguyen'));
    expect(user.fullName, 'Linh Nguyen');
  });

  test('updateProfile carries the avatar url through', () async {
    final source = FakeAuthDataSource(row: row());
    final repository = AuthRepositoryImpl(source, source);

    await repository.updateProfile(fullName: 'Linh', avatarUrl: 'https://cdn/x.jpg');

    expect(source.lastAvatarUrl, 'https://cdn/x.jpg');
  });

  test('completeOnboarding stamps the current user', () async {
    final source = FakeAuthDataSource(row: row());

    await AuthRepositoryImpl(source, source).completeOnboarding();

    expect(source.calls, contains('stampOnboardingCompleted:uid-1'));
  });

  test('a profile write without a session is refused', () async {
    final source = FakeAuthDataSource(userId: null);
    final repository = AuthRepositoryImpl(source, source);

    expect(
      () => repository.updateProfile(fullName: 'Linh'),
      throwsA(isA<UnauthorizedException>()),
    );
  });
}
