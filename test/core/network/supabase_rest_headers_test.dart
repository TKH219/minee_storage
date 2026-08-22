import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/network/interceptors/supabase_rest_interceptor.dart';

void main() {
  RequestOptions run(SupabaseRestInterceptor interceptor, {Map<String, dynamic>? extra}) {
    final options = RequestOptions(path: '/rest/v1/stores', extra: extra ?? {});
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

  test('an endpoint marked as not needing auth gets the anon key, not the session', () {
    final options = run(
      SupabaseRestInterceptor(anonKey: 'anon-123', accessToken: () => 'jwt-abc'),
      extra: {SupabaseRestInterceptor.requiresAuthKey: false},
    );

    expect(options.headers['apikey'], 'anon-123');
    expect(options.headers['Authorization'], 'Bearer anon-123');
  });

  test('the session token is still attached when the flag is absent', () {
    final options = run(
      SupabaseRestInterceptor(anonKey: 'anon-123', accessToken: () => 'jwt-abc'),
      extra: {'unrelated': true},
    );

    expect(options.headers['Authorization'], 'Bearer jwt-abc');
  });

  test('the flag set true behaves as the default', () {
    final options = run(
      SupabaseRestInterceptor(anonKey: 'anon-123', accessToken: () => 'jwt-abc'),
      extra: {SupabaseRestInterceptor.requiresAuthKey: true},
    );

    expect(options.headers['Authorization'], 'Bearer jwt-abc');
  });

  test('a stale session cannot break an endpoint that never needed it', () {
    // This is the point of the flag: signup and forgot-password call
    // email_status before signing in, and an expired token left over from a
    // previous session would otherwise be sent and rejected.
    final options = run(
      SupabaseRestInterceptor(anonKey: 'anon-123', accessToken: () => 'expired-jwt'),
      extra: {SupabaseRestInterceptor.requiresAuthKey: false},
    );

    expect(options.headers['Authorization'], isNot(contains('expired-jwt')));
  });
}
