import 'package:mine_storage/core/exceptions/error_action.dart';
import 'package:mine_storage/core/exceptions/error_policy.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/storage/user_state_purger.dart';

/// Carries out whatever `ErrorPolicy` decided.
///
/// Side effects arrive as callbacks rather than a router or a messenger key, so
/// the whole class is exercised in plain unit tests.
class AppErrorHandler {
  const AppErrorHandler({
    required UserStatePurger purger,
    required void Function(String message) showSnack,
    required void Function(String routeName) redirect,
  }) : _purger = purger,
       _showSnack = showSnack,
       _redirect = redirect;

  final UserStatePurger _purger;
  final void Function(String message) _showSnack;
  final void Function(String routeName) _redirect;

  /// [present] lets one call site render the error itself. It suppresses the
  /// snack only — a caller can never opt out of a purge or a redirect.
  Future<void> handle(AppException error, {bool present = true}) async {
    final action = ErrorPolicy.resolve(error);

    if (action.purgesUserState) {
      await _purger.purge();
    }

    if (present && action.presentation == ErrorPresentation.snack) {
      _showSnack(error.displayMessage);
    }

    final routeName = action.redirectRouteName;
    if (routeName != null) {
      _redirect(routeName);
    }
  }
}
