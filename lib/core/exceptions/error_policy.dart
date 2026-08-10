import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/exceptions/error_action.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';

/// The single table of what the app does about each failure.
///
/// Pure by design: every row is a value in, a value out. `AppErrorHandler` is
/// the only thing allowed to act on the result, so this stays readable as the
/// one place the rules live.
class ErrorPolicy {
  const ErrorPolicy._();

  static ErrorAction resolve(AppException error) {
    // Ordered subtype-first: SessionExpiredException is an UnauthorizedException.
    if (error is SessionExpiredException) {
      return const ErrorAction(
        presentation: ErrorPresentation.snack,
        purgesUserState: true,
        redirectRouteName: AppRoutes.signInName,
      );
    }

    if (error is UnauthorizedException) return const ErrorAction.snack();
    if (error is ForbiddenException) return const ErrorAction.snack();
    if (error is BadRequestException) return const ErrorAction.inline();
    if (error is NotFoundException) return const ErrorAction.inline();
    if (error is NetworkException) return const ErrorAction.snack();
    if (error is CancelledException) return const ErrorAction.silent();
    if (error is CacheException) return const ErrorAction.silent();

    // A business code is always something the user acts on in a form; a bare
    // server failure is not.
    if (error is ServerException) {
      return error.errorCode != null ? const ErrorAction.inline() : const ErrorAction.snack();
    }

    return const ErrorAction.snack();
  }
}
