import 'package:dio/dio.dart';

/// Supplies the two headers PostgREST and Storage require.
///
/// `apikey` is always the anon key — it identifies the project, not the caller.
/// The bearer is the session token when there is one, and the anon key
/// otherwise, which is what makes an unauthenticated call resolve to the `anon`
/// role rather than being rejected outright.
class SupabaseRestInterceptor extends Interceptor {
  SupabaseRestInterceptor({required this.anonKey, required this.accessToken});

  final String anonKey;
  final String? Function() accessToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = accessToken();
    options.headers['apikey'] = anonKey;
    options.headers['Authorization'] =
        'Bearer ${token == null || token.isEmpty ? anonKey : token}';
    handler.next(options);
  }
}
