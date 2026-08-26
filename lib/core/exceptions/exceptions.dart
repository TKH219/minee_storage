import 'package:decimal/decimal.dart';

import 'package:mine_storage/l10n/locale_keys.g.dart';
/// Base type for every error this app raises out of the data layer.
///
/// [ErrorInterceptor] converts any `DioException` into one of these, so state
/// notifiers only ever have to reason about [AppException] subtypes.
abstract class AppException implements Exception {
  const AppException({this.message, this.errorCode, this.statusCode});

  final String? message;
  final String? errorCode;
  final int? statusCode;

  /// Message safe to surface in the UI.
  String get messageKey => LocaleKeys.errors_generic;

  @override
  String toString() => '$runtimeType: ${statusCode ?? ''} ${message ?? ''}'.trim();
}

/// A response came back and it was a failure — as opposed to never reaching the
/// server at all. Catch this to handle any remote failure in one clause.
abstract class HttpException extends AppException {
  const HttpException({super.message, super.errorCode, super.statusCode});
}

/// A local storage failure — the keychain, preferences, or an on-device
/// database. Never involves the network.
abstract class DatabaseException extends AppException {
  const DatabaseException({super.message, super.errorCode});
}

class ServerException extends HttpException {
  const ServerException({super.message, super.statusCode, super.errorCode});

  @override
  String get messageKey => LocaleKeys.errors_server;
}

class CacheException extends DatabaseException {
  const CacheException({super.message});

  @override
  String get messageKey => LocaleKeys.errors_cache;
}

/// The request never got an answer — no connectivity, a timeout, a dead host.
class NetworkException extends AppException {
  const NetworkException({super.message});

  @override
  String get messageKey => LocaleKeys.errors_network;
}

class NotFoundException extends HttpException {
  const NotFoundException({super.message, super.statusCode});

  @override
  String get messageKey => LocaleKeys.errors_notFound;
}

class BadRequestException extends HttpException {
  const BadRequestException({super.message, super.statusCode, this.errors});

  /// Field-level validation errors keyed by field name.
  final Map<String, dynamic>? errors;

  @override
  String get messageKey => LocaleKeys.errors_badRequest;

  @override
  String toString() =>
      'BadRequestException: ${message ?? 'Bad request.'}'
      '${errors != null ? ' Errors: $errors' : ''}';
}

class UnauthorizedException extends HttpException {
  const UnauthorizedException({super.message, super.errorCode, super.statusCode});

  @override
  String get messageKey => LocaleKeys.errors_unauthorized;
}

/// The session itself is gone, as opposed to credentials being rejected at
/// sign-in — both are 401-shaped, but only this one may purge user state and
/// bounce to sign-in. Keeping them apart is what stops a wrong password on the
/// sign-in form from wiping the device.
class SessionExpiredException extends UnauthorizedException {
  const SessionExpiredException({super.message, super.errorCode, super.statusCode});

  @override
  String get messageKey => LocaleKeys.errors_sessionExpired;
}

class ForbiddenException extends HttpException {
  const ForbiddenException({super.message, super.statusCode});

  @override
  String get messageKey => LocaleKeys.errors_forbidden;
}

class CancelledException extends AppException {
  const CancelledException({super.message});

  @override
  String get messageKey => LocaleKeys.errors_cancelled;
}

/// A failure raised by Supabase rather than by the REST API.
///
/// Supabase reports failures as prose, never as an error code, so these are the
/// codes: the mapper turns each recognised message into one leaf, and features
/// switch on the type instead of matching strings. Deliberately not an
/// [HttpException] — nothing here carries a status code worth reasoning about.
abstract class SupabaseException extends AppException {
  const SupabaseException({super.message});
}

class InvalidCredentialsException extends SupabaseException {
  const InvalidCredentialsException({super.message});

  @override
  String get messageKey => LocaleKeys.errors_invalidCredentials;
}

class InvalidCodeException extends SupabaseException {
  const InvalidCodeException({super.message});

  @override
  String get messageKey => LocaleKeys.errors_invalidCode;
}

class EmailAlreadyRegisteredException extends SupabaseException {
  const EmailAlreadyRegisteredException({super.message});

  @override
  String get messageKey => LocaleKeys.errors_emailAlreadyRegistered;
}

class WeakPasswordException extends SupabaseException {
  const WeakPasswordException({super.message});

  @override
  String get messageKey => LocaleKeys.errors_weakPassword;
}

class RateLimitedException extends SupabaseException {
  const RateLimitedException({super.message});

  @override
  String get messageKey => LocaleKeys.errors_rateLimited;
}

class EmailNotConfirmedException extends SupabaseException {
  const EmailNotConfirmedException({super.message});

  @override
  String get messageKey => LocaleKeys.errors_emailNotConfirmed;
}

/// The stored session is gone. The purge is driven by the auth state stream,
/// not by anyone catching this — it exists so a feature can word its own
/// message when a call fails for this reason.
class SupabaseSessionExpiredException extends SupabaseException {
  const SupabaseSessionExpiredException({super.message});

  @override
  String get messageKey => LocaleKeys.errors_sessionExpired;
}

class UnknownSupabaseException extends SupabaseException {
  const UnknownSupabaseException({super.message});

  @override
  String get messageKey => LocaleKeys.errors_generic;
}

/// Raised by the FEFO allocator before any request leaves the device, so a
/// short consume attempt changes nothing.
///
/// Deliberately not an [HttpException]: nothing was sent. The quantities are
/// carried so a feature can word the shortfall itself; [messageKey] stays
/// generic because a translation key cannot interpolate them on its own.
/// Raised when a lot's received quantity is edited down past what has already
/// been drawn out of it. Balancing that would mean inventing a stock movement
/// nobody recorded, so the edit is refused and the correction belongs in a
/// transaction instead.
class QuantityBelowDrawnException extends AppException {
  const QuantityBelowDrawnException({
    this.received,
    this.drawn,
    super.errorCode,
    super.statusCode,
  });

  /// Null when the refusal came back from the server, which names the figures
  /// in its own message rather than in a structured field.
  final Decimal? received;
  final Decimal? drawn;

  @override
  String get messageKey => LocaleKeys.errors_quantityBelowDrawn;

  @override
  String toString() =>
      'QuantityBelowDrawnException: received $received, already drawn $drawn';
}

class InsufficientStockException extends AppException {
  const InsufficientStockException({required this.requested, required this.available});

  final Decimal requested;
  final Decimal available;

  @override
  String get messageKey => LocaleKeys.errors_insufficientStock;

  @override
  String toString() =>
      'InsufficientStockException: requested $requested, available $available';
}
