import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/exceptions/error_action.dart';
import 'package:mine_storage/core/exceptions/error_codes.dart';
import 'package:mine_storage/core/exceptions/error_policy.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';

void main() {
  group('a dead session', () {
    test('purges, redirects to sign-in and snacks', () {
      final action = ErrorPolicy.resolve(const SessionExpiredException());

      expect(action.presentation, ErrorPresentation.snack);
      expect(action.purgesUserState, isTrue);
      expect(action.redirectRouteName, AppRoutes.signInName);
    });

    test('is the only action that purges', () {
      final purging = [
        const SessionExpiredException(),
        const UnauthorizedException(),
        const ForbiddenException(),
        const BadRequestException(),
        const NotFoundException(),
        const ServerException(),
        const NetworkException(),
        const CancelledException(),
        const CacheException(),
      ].where((e) => ErrorPolicy.resolve(e).purgesUserState);

      expect(purging, [isA<SessionExpiredException>()]);
    });
  });

  group('rejected credentials', () {
    test('snack only — never purges or redirects', () {
      final action = ErrorPolicy.resolve(const UnauthorizedException());

      expect(action.presentation, ErrorPresentation.snack);
      expect(action.purgesUserState, isFalse);
      expect(action.redirectRouteName, isNull);
    });
  });

  group('presentation', () {
    test('403 snacks', () {
      expect(
        ErrorPolicy.resolve(const ForbiddenException()).presentation,
        ErrorPresentation.snack,
      );
    });

    test('validation failures render inline on the form', () {
      expect(
        ErrorPolicy.resolve(const BadRequestException()).presentation,
        ErrorPresentation.inline,
      );
    });

    test('a missing resource renders inline', () {
      expect(
        ErrorPolicy.resolve(const NotFoundException()).presentation,
        ErrorPresentation.inline,
      );
    });

    test('a business code renders inline', () {
      expect(
        ErrorPolicy.resolve(
          const ServerException(errorCode: ServerErrorCodes.userWasLocked),
        ).presentation,
        ErrorPresentation.inline,
      );
    });

    test('a bare server failure snacks', () {
      expect(
        ErrorPolicy.resolve(const ServerException(statusCode: 500)).presentation,
        ErrorPresentation.snack,
      );
    });

    test('a network failure snacks', () {
      expect(
        ErrorPolicy.resolve(const NetworkException()).presentation,
        ErrorPresentation.snack,
      );
    });

    test('a cancelled request is silent', () {
      expect(
        ErrorPolicy.resolve(const CancelledException()).presentation,
        ErrorPresentation.silent,
      );
    });

    test('a cache failure is silent', () {
      expect(
        ErrorPolicy.resolve(const CacheException()).presentation,
        ErrorPresentation.silent,
      );
    });
  });

  test('every AppException resolves to an action', () {
    expect(ErrorPolicy.resolve(const _UnknownException()).presentation, ErrorPresentation.snack);
  });
}

class _UnknownException extends AppException {
  const _UnknownException();
}
