import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/exceptions/supabase_error_mapper.dart';

void main() {
  test('maps invalid credentials to UnauthorizedException, not a dead session', () {
    final result = SupabaseErrorMapper.map(
      const AuthException('Invalid login credentials'),
    );

    expect(result, isA<UnauthorizedException>());
    expect(result, isNot(isA<SessionExpiredException>()));
    expect(result.displayMessage, 'Incorrect email or password.');
  });

  for (final message in [
    'JWT expired',
    'Session from session_id claim in JWT does not exist',
    'invalid claim: missing sub claim',
  ]) {
    test('maps "$message" to SessionExpiredException', () {
      expect(
        SupabaseErrorMapper.map(AuthException(message)),
        isA<SessionExpiredException>(),
      );
    });
  }

  test('maps an expired or wrong code to BadRequestException', () {
    final result = SupabaseErrorMapper.map(
      const AuthException('Token has expired or is invalid'),
    );

    expect(result, isA<BadRequestException>());
    expect(result.displayMessage, 'That code is invalid or has expired.');
  });

  test('maps an already-registered email to BadRequestException', () {
    final result = SupabaseErrorMapper.map(
      const AuthException('User already registered'),
    );

    expect(result, isA<BadRequestException>());
    expect(result.displayMessage, 'That email is already registered.');
  });

  test('maps a weak password to BadRequestException', () {
    final result = SupabaseErrorMapper.map(
      const AuthException('Password should be at least 6 characters'),
    );

    expect(result, isA<BadRequestException>());
    expect(result.displayMessage, 'Password must be at least 6 characters.');
  });

  test('maps an email rate limit to ServerException', () {
    final result = SupabaseErrorMapper.map(
      const AuthException('email rate limit exceeded'),
    );

    expect(result, isA<ServerException>());
    expect(
      result.displayMessage,
      'Too many emails sent. Please wait a minute and try again.',
    );
  });

  test('maps an unrecognised AuthException to its own message', () {
    final result = SupabaseErrorMapper.map(const AuthException('Something odd'));

    expect(result, isA<ServerException>());
    expect(result.displayMessage, 'Something odd');
  });

  test('passes an existing AppException straight through', () {
    const original = NetworkException(message: 'offline');

    expect(SupabaseErrorMapper.map(original), same(original));
  });

  test('falls back for a completely unknown error', () {
    final result = SupabaseErrorMapper.map(StateError('boom'));

    expect(result, isA<ServerException>());
    expect(result.displayMessage, 'Something went wrong. Please try again.');
  });
}
