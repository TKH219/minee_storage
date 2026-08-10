import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/error_codes.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/network/interceptors/error_interceptor.dart';

void main() {
  final requestOptions = RequestOptions(path: '/anything');

  DioException badResponse({int? statusCode, Object? data}) {
    return DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: statusCode,
        data: data,
      ),
    );
  }

  group('ErrorInterceptor.mapError transport failures', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
      DioExceptionType.connectionError,
    ]) {
      test('$type maps to NetworkException', () {
        final result = ErrorInterceptor.mapError(
          DioException(requestOptions: requestOptions, type: type),
        );
        expect(result, isA<NetworkException>());
      });
    }

    test('cancel maps to CancelledException', () {
      final result = ErrorInterceptor.mapError(
        DioException(requestOptions: requestOptions, type: DioExceptionType.cancel),
      );
      expect(result, isA<CancelledException>());
    });

    test('badCertificate maps to ServerException', () {
      final result = ErrorInterceptor.mapError(
        DioException(requestOptions: requestOptions, type: DioExceptionType.badCertificate),
      );
      expect(result, isA<ServerException>());
    });
  });

  group('ErrorInterceptor.mapError status codes', () {
    test('400 maps to BadRequestException and keeps field errors', () {
      final result = ErrorInterceptor.mapError(
        badResponse(
          statusCode: 400,
          data: {
            'message': 'Validation failed',
            'errors': {'email': 'required'},
          },
        ),
      );

      expect(result, isA<BadRequestException>());
      expect(result.message, 'Validation failed');
      expect((result as BadRequestException).errors, {'email': 'required'});
    });

    test('401 maps to SessionExpiredException', () {
      expect(
        ErrorInterceptor.mapError(badResponse(statusCode: 401)),
        isA<SessionExpiredException>(),
      );
    });

    test('403 maps to ForbiddenException', () {
      expect(ErrorInterceptor.mapError(badResponse(statusCode: 403)), isA<ForbiddenException>());
    });

    test('404 maps to NotFoundException', () {
      expect(ErrorInterceptor.mapError(badResponse(statusCode: 404)), isA<NotFoundException>());
    });

    test('500 maps to ServerException and preserves the status code', () {
      final result = ErrorInterceptor.mapError(badResponse(statusCode: 500));
      expect(result, isA<ServerException>());
      expect(result.statusCode, 500);
    });

    test('a non-map body does not throw', () {
      final result = ErrorInterceptor.mapError(badResponse(statusCode: 503, data: 'plain text'));
      expect(result, isA<ServerException>());
    });
  });

  group('ErrorInterceptor.mapError business codes', () {
    test('business code wins over the HTTP status', () {
      final result = ErrorInterceptor.mapError(
        badResponse(statusCode: 400, data: {'code': ServerErrorCodes.wrongEmailOrPassword}),
      );

      expect(result, isA<ServerException>());
      expect(result.errorCode, ServerErrorCodes.wrongEmailOrPassword);
      expect(result.message, 'Invalid email or password');
    });

    test('tokenExpired maps to SessionExpiredException', () {
      final result = ErrorInterceptor.mapError(
        badResponse(statusCode: 400, data: {'code': ServerErrorCodes.tokenExpired}),
      );

      expect(result, isA<SessionExpiredException>());
      expect(result.errorCode, ServerErrorCodes.tokenExpired);
    });

    for (final code in [
      ServerErrorCodes.tokenInvalid,
      ServerErrorCodes.unauthorised,
    ]) {
      test('$code maps to SessionExpiredException', () {
        expect(
          ErrorInterceptor.mapError(badResponse(statusCode: 401, data: {'code': code})),
          isA<SessionExpiredException>(),
        );
      });
    }

    test('an unknown business code falls through to status mapping', () {
      final result = ErrorInterceptor.mapError(
        badResponse(statusCode: 404, data: {'code': 'SOMETHING_NEW'}),
      );
      expect(result, isA<NotFoundException>());
    });
  });

  test('onError rejects with the typed exception attached to DioException.error', () async {
    final interceptor = ErrorInterceptor();
    final source = badResponse(statusCode: 404);

    Object? captured;
    final handler = _CapturingHandler((e) => captured = e.error);
    interceptor.onError(source, handler);

    expect(captured, isA<NotFoundException>());
  });
}

class _CapturingHandler extends ErrorInterceptorHandler {
  _CapturingHandler(this.onReject);

  final void Function(DioException) onReject;

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) =>
      onReject(error);
}
