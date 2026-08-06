import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:mine_storage/data/models/models.dart';

part 'auth_api.g.dart';

/// Anonymous endpoints — bound to the public Dio instance, which carries no
/// `Authorization` header and no refresh interceptor.
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String? baseUrl}) = _AuthApi;

  @POST('/auth/login')
  Future<BaseResponse<LoginResponse>> login(@Body() LoginRequest request);
}

/// Authenticated endpoints — bound to the authorized Dio instance.
@RestApi()
abstract class AuthorizedAuthApi {
  factory AuthorizedAuthApi(Dio dio, {String? baseUrl}) = _AuthorizedAuthApi;

  @POST('/auth/logout')
  Future<void> logout();
}
