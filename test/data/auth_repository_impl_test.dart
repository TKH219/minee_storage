import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/repositories/auth_repository_impl.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';

import '../support/fake_auth_data_source.dart';

Map<String, dynamic> row({bool deactivated = false, String shop = 'Minee'}) => {
  'id': 'uid-1',
  'email': 'a@b.com',
  'shop_name': shop,
  'is_deactivated': deactivated,
  'last_signed_in_at': null,
};

void main() {
  test('signIn returns the user and stamps last_signed_in_at', () async {
    final source = FakeAuthDataSource(row: row());
    final repository = AuthRepositoryImpl(source);

    final user = await repository.signIn(email: 'A@B.com ', password: 'secret');

    expect(user.id, 'uid-1');
    expect(user.shopName, 'Minee');
    expect(source.calls, contains('signIn:a@b.com'));
    expect(source.calls, contains('touch:uid-1'));
  });

  test('signIn refuses a deactivated user and signs them out', () async {
    final source = FakeAuthDataSource(row: row(deactivated: true));
    final repository = AuthRepositoryImpl(source);

    await expectLater(
      () => repository.signIn(email: 'a@b.com', password: 'secret'),
      throwsA(
        isA<ForbiddenException>().having(
          (e) => e.displayMessage,
          'displayMessage',
          'This account has been deactivated. Please contact us for support.',
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
    final repository = AuthRepositoryImpl(source);

    final user = await repository.signIn(email: 'a@b.com', password: 'secret');

    expect(user.id, 'uid-1');
  });

  test('signIn maps invalid credentials', () async {
    final source = FakeAuthDataSource(
      signInError: const AuthException('Invalid login credentials'),
    );
    final repository = AuthRepositoryImpl(source);

    await expectLater(
      () => repository.signIn(email: 'a@b.com', password: 'wrong'),
      throwsA(isA<InvalidCredentialsException>()),
    );
  });

  test('signIn throws when the users row is missing', () async {
    final source = FakeAuthDataSource(row: null);
    final repository = AuthRepositoryImpl(source);

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
      final repository = AuthRepositoryImpl(source);

      expect(await repository.checkEmail('a@b.com'), entry.value);
    }
  });

  test('checkEmail treats an unrecognised rpc value as none', () async {
    final repository = AuthRepositoryImpl(FakeAuthDataSource(status: 'weird'));

    expect(await repository.checkEmail('a@b.com'), EmailStatus.none);
  });

  test('startSignUp forwards a normalised email and the shop name', () async {
    final source = FakeAuthDataSource();
    final repository = AuthRepositoryImpl(source);

    await repository.startSignUp(
      email: ' A@B.com ',
      password: 'secret',
      shopName: 'Minee Storage',
    );

    expect(source.calls, contains('signUp:a@b.com'));
    expect(source.lastShopName, 'Minee Storage');
  });

  test('confirmSignUp returns the user without touching shop_name', () async {
    final source = FakeAuthDataSource(row: row(shop: 'Original'));
    final repository = AuthRepositoryImpl(source);

    final user = await repository.confirmSignUp(
      email: 'a@b.com',
      token: '12345678',
      shopName: 'Original',
      wasResumed: false,
    );

    expect(user.shopName, 'Original');
    expect(source.calls.where((c) => c.startsWith('updateShopName')), isEmpty);
  });

  test('a resumed signup overwrites the shop name the trigger stored', () async {
    final source = FakeAuthDataSource(row: row(shop: 'Old Name'));
    final repository = AuthRepositoryImpl(source);

    final user = await repository.confirmSignUp(
      email: 'a@b.com',
      token: '12345678',
      shopName: 'New Name',
      wasResumed: true,
    );

    expect(source.calls, contains('updateShopName:New Name'));
    expect(user.shopName, 'New Name');
  });

  test('confirmSignUp maps a bad code', () async {
    final source = FakeAuthDataSource(
      verifyError: const AuthException('Token has expired or is invalid'),
    );
    final repository = AuthRepositoryImpl(source);

    await expectLater(
      () => repository.confirmSignUp(
        email: 'a@b.com',
        token: '00000000',
        shopName: 'S',
        wasResumed: false,
      ),
      throwsA(isA<InvalidCodeException>()),
    );
  });

  test('startPasswordReset sends to a normalised email', () async {
    final source = FakeAuthDataSource();
    final repository = AuthRepositoryImpl(source);

    await repository.startPasswordReset(' A@B.com ');

    expect(source.calls, contains('reset:a@b.com'));
  });

  test('verifyPasswordResetCode maps an expired code', () async {
    final source = FakeAuthDataSource(
      verifyError: const AuthException('Token has expired or is invalid'),
    );
    final repository = AuthRepositoryImpl(source);

    await expectLater(
      () => repository.verifyPasswordResetCode(email: 'a@b.com', token: '00000000'),
      throwsA(isA<InvalidCodeException>()),
    );
  });

  test('setNewPassword updates then signs out, in that order', () async {
    final source = FakeAuthDataSource();
    final repository = AuthRepositoryImpl(source);

    await repository.setNewPassword('brand-new');

    expect(source.lastPassword, 'brand-new');
    expect(
      source.calls.indexOf('updatePassword') < source.calls.indexOf('signOut'),
      isTrue,
    );
  });
}
