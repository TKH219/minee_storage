import 'package:dio/dio.dart';

/// Attaches the current Supabase access token to every outgoing request.
///
/// Takes a getter rather than a client so it can be unit-tested without
/// initialising Supabase.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.accessToken});

  final String? Function() accessToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = accessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
