import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:mine_storage/core/constants.dart';

import 'interceptors/error_interceptor.dart';

/// Builds the app's Dio instances.
///
/// Interceptor order matters: [ErrorInterceptor] must be last, because it
/// rejects and therefore terminates the error chain — anything after it would
/// never run.
///
/// [interceptors] is a callback rather than a list so an interceptor can hold a
/// reference to the very Dio it is installed on ([RefreshTokenInterceptor]
/// needs this to replay the original request).
Dio buildDio({
  required String baseUrl,
  List<Interceptor> Function(Dio dio)? interceptors,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Constants.networkTimeout,
      sendTimeout: Constants.networkTimeout,
      receiveTimeout: Constants.networkTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    ...?interceptors?.call(dio),
    if (kDebugMode)
      PrettyDioLogger(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: false,
        maxWidth: 120,
      ),
    ErrorInterceptor(),
  ]);

  return dio;
}
