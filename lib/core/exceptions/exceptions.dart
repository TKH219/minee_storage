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

class ServerException extends AppException {
  const ServerException({super.message, super.statusCode, super.errorCode});

  @override
  String get displayMessage => message ?? 'An unexpected server error occurred.';
}

class CacheException extends AppException {
  const CacheException({super.message});

  @override
  String get displayMessage => message ?? 'An unexpected cache error occurred.';
}

class NetworkException extends AppException {
  const NetworkException({super.message});

  @override
  String get displayMessage => message ?? 'No internet connection. Please check your network.';
}

class NotFoundException extends AppException {
  const NotFoundException({super.message, super.statusCode});

  @override
  String get displayMessage => message ?? 'Resource not found.';
}

class BadRequestException extends AppException {
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

class UnauthorizedException extends AppException {
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

class ForbiddenException extends AppException {
  const ForbiddenException({super.message, super.statusCode});

  @override
  String get displayMessage => message ?? 'You do not have access to this resource.';
}

class CancelledException extends AppException {
  const CancelledException({super.message});

  @override
  String get displayMessage => message ?? 'Request was cancelled.';
}
