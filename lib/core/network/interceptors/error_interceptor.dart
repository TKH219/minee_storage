import 'package:dio/dio.dart';

import 'package:mine_storage/core/exceptions/error_codes.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';

/// Single place where a transport failure becomes a domain error.
///
/// Every failure is re-emitted as a `DioException` whose `.error` holds the
/// typed [AppException] — Retrofit only propagates `DioException`, so throwing
/// a bare [AppException] here would be swallowed. Callers unwrap one level
/// (`BaseStateNotifier.resolveErrorMessage` does this for you).
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        stackTrace: err.stackTrace,
        error: mapError(err),
      ),
    );
  }

  /// Exposed for testing — this is the entire error contract of the app.
  static AppException mapError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(message: 'Network connection error or timeout: ${err.message}');

      case DioExceptionType.cancel:
        return const CancelledException(message: 'Request to API server was cancelled.');

      case DioExceptionType.badCertificate:
        return const ServerException(message: 'Bad SSL/TLS certificate.');

      case DioExceptionType.unknown:
        return ServerException(message: 'An unknown error occurred: ${err.message}');

      case DioExceptionType.badResponse:
        return _mapBadResponse(err);
    }
  }

  static AppException _mapBadResponse(DioException err) {
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;
    final body = data is Map ? data : const <String, dynamic>{};

    final businessCode = body['code'] as String?;
    final message = (body['message'] as String?) ?? businessCode;
    final errors = body['errors'] is Map<String, dynamic>
        ? body['errors'] as Map<String, dynamic>
        : null;

    // Business codes win over HTTP status: the backend uses 400 for several
    // distinct, individually-actionable failures.
    final byCode = _mapBusinessCode(businessCode, statusCode);
    if (byCode != null) return byCode;

    return switch (statusCode) {
      400 || 422 => BadRequestException(
        message: message ?? 'Bad request.',
        statusCode: statusCode,
        errors: errors,
      ),
      401 => SessionExpiredException(message: message, statusCode: statusCode),
      403 => ForbiddenException(message: message, statusCode: statusCode),
      404 => NotFoundException(message: message, statusCode: statusCode),
      409 => ServerException(message: message, statusCode: statusCode),
      500 || 502 || 503 || 504 => ServerException(
        message: 'Server error: ${message ?? 'please try again later.'}',
        statusCode: statusCode,
      ),
      _ => ServerException(
        message: 'Received invalid status code: $statusCode'
            '${message != null ? ', message: $message' : ''}',
        statusCode: statusCode,
      ),
    };
  }

  static AppException? _mapBusinessCode(String? code, int? statusCode) {
    return switch (code) {
      ServerErrorCodes.wrongEmailOrPassword => const ServerException(
        message: 'Invalid email or password',
        errorCode: ServerErrorCodes.wrongEmailOrPassword,
      ),
      ServerErrorCodes.wrongPassword => const ServerException(
        message: 'Incorrect password',
        errorCode: ServerErrorCodes.wrongPassword,
      ),
      ServerErrorCodes.userWasLocked => const ServerException(
        message: 'User account has been locked. Please try again after 30 mins',
        errorCode: ServerErrorCodes.userWasLocked,
      ),
      ServerErrorCodes.emailAlreadyExists => const ServerException(
        message: 'Email already exists',
        errorCode: ServerErrorCodes.emailAlreadyExists,
      ),
      ServerErrorCodes.userNameAlreadyExists => const ServerException(
        message: 'Username already exists',
        errorCode: ServerErrorCodes.userNameAlreadyExists,
      ),
      ServerErrorCodes.tokenExpired => const SessionExpiredException(
        message: 'Token has expired',
        errorCode: ServerErrorCodes.tokenExpired,
      ),
      ServerErrorCodes.tokenInvalid => const SessionExpiredException(
        message: 'Invalid token provided',
        errorCode: ServerErrorCodes.tokenInvalid,
      ),
      ServerErrorCodes.quantityBelowDrawn => QuantityBelowDrawnException(
        errorCode: ServerErrorCodes.quantityBelowDrawn,
        statusCode: statusCode,
      ),
      ServerErrorCodes.unauthorised => SessionExpiredException(
        message: 'Unauthorised',
        errorCode: ServerErrorCodes.unauthorised,
        statusCode: statusCode,
      ),
      _ => null,
    };
  }
}
