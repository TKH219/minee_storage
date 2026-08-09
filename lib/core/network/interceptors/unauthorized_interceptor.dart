import 'package:dio/dio.dart';

/// GoTrue refreshes tokens on its own, so a 401 that still reaches here means
/// the session is genuinely gone. [ErrorInterceptor] stays a pure mapper, so
/// the sign-out side effect lives in its own interceptor.
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
