import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/network/interceptors/auth_interceptor.dart';

import '../../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  test('attaches the bearer token when a session exists', () async {
    final interceptor = AuthInterceptor(accessToken: () => 'jwt-123');
    final options = RequestOptions(path: '/products');

    interceptor.onRequest(options, RequestInterceptorHandler());

    expect(options.headers['Authorization'], 'Bearer jwt-123');
  });

  test('sends no Authorization header when signed out', () async {
    final interceptor = AuthInterceptor(accessToken: () => null);
    final options = RequestOptions(path: '/products');

    interceptor.onRequest(options, RequestInterceptorHandler());

    expect(options.headers.containsKey('Authorization'), isFalse);
  });
}
