import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/exceptions/supabase_error_mapper.dart';

void main() {
  AppException map(String message) => SupabaseErrorMapper.map(AuthException(message));

  test('every Supabase failure groups under SupabaseException', () {
    const failures = <SupabaseException>[
      InvalidCredentialsException(),
      InvalidCodeException(),
      EmailAlreadyRegisteredException(),
      WeakPasswordException(),
      RateLimitedException(),
      EmailNotConfirmedException(),
      SupabaseSessionExpiredException(),
      UnknownSupabaseException(),
    ];

    for (final failure in failures) {
      expect(failure, isA<AppException>(), reason: '$failure');
      expect(failure, isNot(isA<HttpException>()), reason: '$failure');
      expect(failure, isNot(isA<DatabaseException>()), reason: '$failure');
    }
  });

  group('the mapper produces a typed leaf', () {
    test('invalid credentials', () {
      expect(map('Invalid login credentials'), isA<InvalidCredentialsException>());
    });

    test('an expired or wrong code', () {
      expect(map('Token has expired or is invalid'), isA<InvalidCodeException>());
      expect(map('Otp has expired'), isA<InvalidCodeException>());
    });

    test('an already-registered email', () {
      expect(map('User already registered'), isA<EmailAlreadyRegisteredException>());
    });

    test('a weak password', () {
      expect(map('Password should be at least 6 characters'), isA<WeakPasswordException>());
    });

    test('a rate limit', () {
      expect(map('Email rate limit exceeded'), isA<RateLimitedException>());
      expect(map('Too many requests'), isA<RateLimitedException>());
    });

    test('an unconfirmed email', () {
      expect(map('Email not confirmed'), isA<EmailNotConfirmedException>());
    });

    test('a dead session', () {
      expect(map('JWT expired'), isA<SupabaseSessionExpiredException>());
    });

    test('anything unrecognised', () {
      expect(map('Something nobody has seen'), isA<UnknownSupabaseException>());
    });
  });

  test('a Postgrest failure maps to a Supabase failure too', () {
    expect(
      SupabaseErrorMapper.map(const PostgrestException(message: 'boom')),
      isA<SupabaseException>(),
    );
  });

  test('an AppException passes straight through', () {
    const original = NetworkException(message: 'offline');
    expect(SupabaseErrorMapper.map(original), same(original));
  });

  test('every leaf carries a message safe to show', () {
    expect(const InvalidCredentialsException().displayMessage, isNotEmpty);
    expect(const InvalidCodeException().displayMessage, isNotEmpty);
    expect(const RateLimitedException().displayMessage, isNotEmpty);
  });
}
