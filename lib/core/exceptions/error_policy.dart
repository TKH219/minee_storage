import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/exceptions/error_action.dart';
import 'package:mine_storage/core/exceptions/error_codes.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';

/// The single table of what the app does about each failure.
///
/// Pure by design: every row is a value in, a value out. `AppErrorHandler` is
/// the only thing allowed to act on the result, so this stays readable as the
/// one place the rules live.
class ErrorPolicy {
  const ErrorPolicy._();

  static const ErrorAction _sessionEnded = ErrorAction(
    presentation: ErrorPresentation.snack,
    purgesUserState: true,
    redirectRouteName: AppRoutes.signInName,
  );

  /// The API's own code is the most specific thing the server told us, so it is
  /// consulted before the exception type. Anything Supabase raises carries no
  /// code and falls straight through to [_byType].
  static ErrorAction resolve(AppException error) =>
      _byErrorCode(error.errorCode) ?? _byType(error);

  static ErrorAction? _byErrorCode(String? errorCode) => switch (errorCode) {
    ServerErrorCodes.tokenExpired ||
    ServerErrorCodes.tokenInvalid ||
    ServerErrorCodes.unauthorised => _sessionEnded,

    ServerErrorCodes.wrongEmailOrPassword ||
    ServerErrorCodes.wrongPassword ||
    ServerErrorCodes.userWasLocked ||
    ServerErrorCodes.emailAlreadyExists ||
    ServerErrorCodes.userNameAlreadyExists => const ErrorAction.inline(),

    _ => null,
  };

  static ErrorAction _byType(AppException error) => switch (error) {
    // Ordered subtype-first: SessionExpiredException is an UnauthorizedException,
    // and the two category cases below match every leaf under them.
    SessionExpiredException() => _sessionEnded,
    UnauthorizedException() => const ErrorAction.snack(),
    ForbiddenException() => const ErrorAction.snack(),
    BadRequestException() || NotFoundException() => const ErrorAction.inline(),
    NetworkException() => const ErrorAction.snack(),
    CancelledException() => const ErrorAction.silent(),

    // Category fallbacks, so a leaf added later behaves sensibly without
    // anyone remembering to add a row above.
    DatabaseException() => const ErrorAction.silent(),
    HttpException() => const ErrorAction.snack(),

    _ => const ErrorAction.snack(),
  };
}
