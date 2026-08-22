import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/network/interceptors/supabase_rest_interceptor.dart';

void main() {
  RequestOptions run(SupabaseRestInterceptor interceptor, {String? token}) {
    final options = RequestOptions(path: '/rest/v1/stores');
    interceptor.onRequest(options, RequestInterceptorHandler());
    return options;
  }

  test('every request carries the anon key, which PostgREST requires', () {
    final options = run(SupabaseRestInterceptor(anonKey: 'anon-123', accessToken: () => null));

    expect(options.headers['apikey'], 'anon-123');
  });

  test('a session token is sent as the bearer, overriding the anon key', () {
    final options = run(
      SupabaseRestInterceptor(anonKey: 'anon-123', accessToken: () => 'jwt-abc'),
    );

    expect(options.headers['apikey'], 'anon-123');
    expect(options.headers['Authorization'], 'Bearer jwt-abc');
  });

  test('without a session the anon key is the bearer too', () {
    final options = run(
      SupabaseRestInterceptor(anonKey: 'anon-123', accessToken: () => null),
    );

    expect(options.headers['Authorization'], 'Bearer anon-123');
  });

  test('an empty token is treated as no token', () {
    final options = run(
      SupabaseRestInterceptor(anonKey: 'anon-123', accessToken: () => ''),
    );

    expect(options.headers['Authorization'], 'Bearer anon-123');
  });
}
