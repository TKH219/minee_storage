import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/exceptions/app_error_handler.dart';
import 'package:mine_storage/core/exceptions/error_codes.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/storage/user_state_purger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  late List<String> snacks;
  late List<String> redirects;
  late bool signedOut;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    snacks = [];
    redirects = [];
    signedOut = false;
  });

  AppErrorHandler handler() {
    return AppErrorHandler(
      purger: UserStatePurger(signOut: () async => signedOut = true),
      showSnack: snacks.add,
      redirect: redirects.add,
    );
  }

  test('a dead session purges, snacks and redirects to sign-in', () async {
    await handler().handle(const SessionExpiredException());

    expect(signedOut, isTrue);
    expect(snacks, ['Your session has expired. Please sign in again.']);
    expect(redirects, [AppRoutes.signInName]);
  });

  test('a server failure snacks and nothing else', () async {
    await handler().handle(const ServerException(message: 'Boom', statusCode: 500));

    expect(snacks, ['Boom']);
    expect(redirects, isEmpty);
    expect(signedOut, isFalse);
  });

  test('an inline error does not snack', () async {
    await handler().handle(const BadRequestException(message: 'Code expired'));

    expect(snacks, isEmpty);
    expect(redirects, isEmpty);
  });

  test('a business code does not snack', () async {
    await handler().handle(
      const ServerException(message: 'Locked', errorCode: ServerErrorCodes.userWasLocked),
    );

    expect(snacks, isEmpty);
  });

  test('a silent error does nothing', () async {
    await handler().handle(const CancelledException());

    expect(snacks, isEmpty);
    expect(redirects, isEmpty);
    expect(signedOut, isFalse);
  });

  group('call-site opt-out', () {
    test('suppresses the snack', () async {
      await handler().handle(const ServerException(message: 'Boom'), present: false);

      expect(snacks, isEmpty);
    });

    test('cannot suppress the purge or the redirect', () async {
      await handler().handle(const SessionExpiredException(), present: false);

      expect(snacks, isEmpty);
      expect(signedOut, isTrue);
      expect(redirects, [AppRoutes.signInName]);
    });
  });
}
