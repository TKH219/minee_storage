import 'package:dio/dio.dart';

/// Signs the user out when the REST API rejects the bearer token.
///
/// GoTrue refreshes tokens on its own, so a 401 that still reaches here means
/// the session is genuinely gone. [ErrorInterceptor] stays a pure mapper, so
/// this side effect lives in its own interceptor.
///
/// It only signs out — clearing stored state is driven by the auth stream, so
/// this path and a Supabase session dying converge on one purge.
class UnauthorizedInterceptor extends Interceptor {
  UnauthorizedInterceptor({required this.onUnauthorized});

  final Future<void> Function() onUnauthorized;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await onUnauthorized();
    }
    handler.next(err);
  }
}
