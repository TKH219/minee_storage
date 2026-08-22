import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'user_api.g.dart';

/// The profile row and the email-existence RPC, over PostgREST.
///
/// Auth itself stays on GoTrue: this covers only what is a table read or write.
@RestApi()
abstract class UserApi {
  factory UserApi(Dio dio, {String? baseUrl}) = _UserApi;

  @GET('/rest/v1/users')
  Future<dynamic> fetchUser({
    @Query('id') required String id,
    @Query('select') String select = '*',
  });

  @PATCH('/rest/v1/users')
  Future<void> updateUser(
    @Query('id') String id,
    @Body() Map<String, dynamic> values,
  );

  @POST('/rest/v1/rpc/email_status')
  Future<String> emailStatus(@Body() Map<String, dynamic> body);
}
