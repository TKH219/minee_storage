import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/repositories/auth_repository_impl.dart';

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
      throwsA(isA<UnauthorizedException>()),
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
}
