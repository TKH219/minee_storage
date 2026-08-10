import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';

void main() {
  // The `List<AppException>` annotation is the assertion: this list only
  // compiles while every exception still descends from AppException.
  const allExceptions = <AppException>[
    ServerException(),
    CacheException(),
    NetworkException(),
    NotFoundException(),
    BadRequestException(),
    UnauthorizedException(),
    SessionExpiredException(),
    ForbiddenException(),
    CancelledException(),
  ];

  test('every exception offers a non-empty message for the UI', () {
    for (final exception in allExceptions) {
      expect(exception.displayMessage, isNotEmpty, reason: '$exception');
    }
  });

  test('every exception is catchable as one Exception type', () {
    for (final exception in allExceptions) {
      expect(() => throw exception, throwsA(isA<AppException>()));
    }
  });

  group('a response came back', () {
    const httpExceptions = <AppException>[
      BadRequestException(),
      UnauthorizedException(),
      SessionExpiredException(),
      ForbiddenException(),
      NotFoundException(),
      ServerException(),
    ];

    test('all group under HttpException', () {
      for (final exception in httpExceptions) {
        expect(exception, isA<HttpException>(), reason: '$exception');
      }
    });

    test('a failure with no response does not', () {
      expect(const NetworkException(), isNot(isA<HttpException>()));
      expect(const CancelledException(), isNot(isA<HttpException>()));
      expect(const CacheException(), isNot(isA<HttpException>()));
    });
  });

  group('local storage', () {
    test('CacheException groups under DatabaseException', () {
      expect(const CacheException(), isA<DatabaseException>());
    });

    test('a transport failure does not', () {
      expect(const NetworkException(), isNot(isA<DatabaseException>()));
      expect(const ServerException(), isNot(isA<DatabaseException>()));
    });
  });

  test('a category can be caught in one clause', () {
    AppException? caught;
    try {
      throw const NotFoundException(message: 'gone');
    } on HttpException catch (e) {
      caught = e;
    }

    expect(caught, isA<NotFoundException>());
  });

  test('the status code survives the category layer', () {
    const exception = ServerException(message: 'Boom', statusCode: 503);

    expect(exception.statusCode, 503);
    expect(exception.displayMessage, 'Boom');
  });
}
