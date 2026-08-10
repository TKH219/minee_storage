import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/exceptions/error_action.dart';
import 'package:mine_storage/core/exceptions/error_codes.dart';
import 'package:mine_storage/core/exceptions/error_policy.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';

void main() {
  group('codes the API returns for a dead session', () {
    for (final code in [
      ServerErrorCodes.tokenExpired,
      ServerErrorCodes.tokenInvalid,
      ServerErrorCodes.unauthorised,
    ]) {
      test('$code ends the session', () {
        final action = ErrorPolicy.resolve(ServerException(errorCode: code));

        expect(action.purgesUserState, isTrue);
        expect(action.redirectRouteName, AppRoutes.signInName);
        expect(action.presentation, ErrorPresentation.snack);
      });
    }
  });

  group('codes the user acts on in a form', () {
    for (final code in [
      ServerErrorCodes.wrongEmailOrPassword,
      ServerErrorCodes.wrongPassword,
      ServerErrorCodes.userWasLocked,
      ServerErrorCodes.emailAlreadyExists,
      ServerErrorCodes.userNameAlreadyExists,
    ]) {
      test('$code renders inline and never purges', () {
        final action = ErrorPolicy.resolve(ServerException(errorCode: code));

        expect(action.presentation, ErrorPresentation.inline);
        expect(action.purgesUserState, isFalse);
        expect(action.redirectRouteName, isNull);
      });
    }
  });

  test('the API code wins over the exception type', () {
    // The type alone only snacks — rejected credentials. The code says the
    // session is dead, and the code is the more specific fact.
    final action = ErrorPolicy.resolve(
      const UnauthorizedException(errorCode: ServerErrorCodes.tokenExpired),
    );

    expect(action.purgesUserState, isTrue);
    expect(action.redirectRouteName, AppRoutes.signInName);
  });

  test('an unrecognised code falls through to the type', () {
    final action = ErrorPolicy.resolve(const ServerException(errorCode: 'SOMETHING_NEW'));

    expect(action.presentation, ErrorPresentation.snack);
    expect(action.purgesUserState, isFalse);
  });

  test('no code at all falls through to the type', () {
    expect(
      ErrorPolicy.resolve(const BadRequestException()).presentation,
      ErrorPresentation.inline,
    );
  });
}
