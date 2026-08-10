import 'package:supabase_flutter/supabase_flutter.dart';

import 'exceptions.dart';

/// Supabase throws outside the Dio pipeline, so [ErrorInterceptor] never sees
/// these. This is the equivalent boundary for the auth stack, and the only
/// place `AuthException` and `PostgrestException` are allowed to appear.
///
/// Supabase reports failures as prose with no error code, so matching on the
/// message is the only option. Each match produces a typed [SupabaseException]
/// so nothing downstream has to repeat the string matching.
class SupabaseErrorMapper {
  const SupabaseErrorMapper._();

  static AppException map(Object error) {
    if (error is AppException) return error;

    if (error is AuthException) return _fromAuthMessage(error.message);

    if (error is PostgrestException) {
      return UnknownSupabaseException(message: error.message);
    }

    return const UnknownSupabaseException();
  }

  static SupabaseException _fromAuthMessage(String raw) {
    final message = raw.toLowerCase();

    return switch (message) {
      _ when message.contains('invalid login credentials') =>
        const InvalidCredentialsException(),

      // Checked before the code branch: both mention expiry, but only these
      // mean the stored session is dead rather than a typed code being stale.
      _
          when message.contains('jwt expired') ||
              message.contains('session from session_id') ||
              message.contains('missing sub claim') ||
              message.contains('session not found') =>
        const SupabaseSessionExpiredException(),

      _
          when message.contains('token has expired') ||
              message.contains('invalid token') ||
              (message.contains('otp') && message.contains('expired')) =>
        const InvalidCodeException(),

      _ when message.contains('already registered') => const EmailAlreadyRegisteredException(),

      _ when message.contains('password should be at least') => const WeakPasswordException(),

      _ when message.contains('rate limit') || message.contains('too many requests') =>
        const RateLimitedException(),

      _ when message.contains('email not confirmed') => const EmailNotConfirmedException(),

      _ => UnknownSupabaseException(message: raw),
    };
  }
}
