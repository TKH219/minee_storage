import 'package:dio/dio.dart';

/// Supplies the two headers PostgREST and Storage require.
///
/// `apikey` is always the anon key — it identifies the project, not the caller.
/// The bearer is the session token when there is one, and the anon key
/// otherwise, which is what makes an unauthenticated call resolve to the `anon`
/// role rather than being rejected outright.
///
/// An endpoint that runs before anyone is signed in — `email_status`, reached
/// from signup and forgot-password — opts out with
/// `@Extra({SupabaseRestInterceptor.requiresAuthKey: false})`. Without that, a
/// stale token left over from a previous session would be sent to an endpoint
/// that never needed one, and rejected.
class SupabaseRestInterceptor extends Interceptor {
  SupabaseRestInterceptor({required this.anonKey, required this.accessToken});

  /// Key in `RequestOptions.extra`. Absent means the request needs the session,
  /// so an endpoint keeps its token unless it deliberately gives it up.
  static const String requiresAuthKey = 'requires_auth';

  final String anonKey;
  final String? Function() accessToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requiresAuth = options.extra[requiresAuthKey] as bool? ?? true;
    final token = requiresAuth ? accessToken() : null;

    options.headers['apikey'] = anonKey;
    options.headers['Authorization'] =
        'Bearer ${token == null || token.isEmpty ? anonKey : token}';
    handler.next(options);
  }
}
