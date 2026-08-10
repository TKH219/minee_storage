import 'package:supabase_flutter/supabase_flutter.dart';

import 'exceptions.dart';

/// Supabase throws outside the Dio pipeline, so [ErrorInterceptor] never sees
/// these. This is the equivalent boundary for the auth stack.
class SupabaseErrorMapper {
  const SupabaseErrorMapper._();

  static AppException map(Object error) {
    if (error is AppException) return error;

    if (error is AuthException) {
      final message = error.message.toLowerCase();

      if (message.contains('invalid login credentials')) {
        return const UnauthorizedException(message: 'Incorrect email or password.');
      }
      // Checked before the OTP branch below: both mention expiry, but only
      // these mean the stored session is dead rather than a typed code stale.
      if (message.contains('jwt expired') ||
          message.contains('session from session_id') ||
          message.contains('missing sub claim') ||
          message.contains('session not found')) {
        return const SessionExpiredException();
      }
      if (message.contains('token has expired') ||
          message.contains('invalid token') ||
          message.contains('otp') && message.contains('expired')) {
        return const BadRequestException(message: 'That code is invalid or has expired.');
      }
      if (message.contains('already registered')) {
        return const BadRequestException(message: 'That email is already registered.');
      }
      if (message.contains('password should be at least')) {
        return const BadRequestException(message: 'Password must be at least 6 characters.');
      }
      if (message.contains('rate limit') || message.contains('too many requests')) {
        return const ServerException(
          message: 'Too many emails sent. Please wait a minute and try again.',
        );
      }
      if (message.contains('email not confirmed')) {
        return const BadRequestException(message: 'Please confirm your email first.');
      }
      return ServerException(message: error.message);
    }

    if (error is PostgrestException) {
      return ServerException(message: error.message);
    }

    return const ServerException(message: 'Something went wrong. Please try again.');
  }
}
