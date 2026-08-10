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
  String get displayMessage => message ?? 'Something went wrong. Please try again.';

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
  String get displayMessage => message ?? 'An unexpected server error occurred.';
}

class CacheException extends DatabaseException {
  const CacheException({super.message});

  @override
  String get displayMessage => message ?? 'An unexpected cache error occurred.';
}

/// The request never got an answer — no connectivity, a timeout, a dead host.
class NetworkException extends AppException {
  const NetworkException({super.message});

  @override
  String get displayMessage => message ?? 'No internet connection. Please check your network.';
}

class NotFoundException extends HttpException {
  const NotFoundException({super.message, super.statusCode});

  @override
  String get displayMessage => message ?? 'Resource not found.';
}

class BadRequestException extends HttpException {
  const BadRequestException({super.message, super.statusCode, this.errors});

  /// Field-level validation errors keyed by field name.
  final Map<String, dynamic>? errors;

  @override
  String get displayMessage => message ?? 'Bad request.';

  @override
  String toString() =>
      'BadRequestException: ${message ?? 'Bad request.'}'
      '${errors != null ? ' Errors: $errors' : ''}';
}

class UnauthorizedException extends HttpException {
  const UnauthorizedException({super.message, super.errorCode, super.statusCode});

  @override
  String get displayMessage => message ?? 'Those credentials were not accepted.';
}

/// The session itself is gone, as opposed to credentials being rejected at
/// sign-in — both are 401-shaped, but only this one may purge user state and
/// bounce to sign-in. Keeping them apart is what stops a wrong password on the
/// sign-in form from wiping the device.
class SessionExpiredException extends UnauthorizedException {
  const SessionExpiredException({super.message, super.errorCode, super.statusCode});

  @override
  String get displayMessage => message ?? 'Your session has expired. Please sign in again.';
}

class ForbiddenException extends HttpException {
  const ForbiddenException({super.message, super.statusCode});

  @override
  String get displayMessage => message ?? 'You do not have access to this resource.';
}

class CancelledException extends AppException {
  const CancelledException({super.message});

  @override
  String get displayMessage => message ?? 'Request was cancelled.';
}
