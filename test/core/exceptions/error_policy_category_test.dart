import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/error_action.dart';
import 'package:mine_storage/core/exceptions/error_policy.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';

/// A leaf nobody has written yet, to prove the category fallbacks catch it.
class _FutureHttpException extends HttpException {
  const _FutureHttpException();
}

class _FutureDatabaseException extends DatabaseException {
  const _FutureDatabaseException();
}

void main() {
  test('an unrecognised HTTP failure falls back to a snack', () {
    expect(
      ErrorPolicy.resolve(const _FutureHttpException()).presentation,
      ErrorPresentation.snack,
    );
  });

  test('an unrecognised storage failure falls back to silent', () {
    expect(
      ErrorPolicy.resolve(const _FutureDatabaseException()).presentation,
      ErrorPresentation.silent,
    );
  });

  test('a category fallback never purges', () {
    expect(ErrorPolicy.resolve(const _FutureHttpException()).purgesUserState, isFalse);
    expect(ErrorPolicy.resolve(const _FutureDatabaseException()).purgesUserState, isFalse);
  });
}
