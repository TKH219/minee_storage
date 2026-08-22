import 'package:dio/dio.dart';

import 'package:mine_storage/core/network/interceptors/supabase_rest_interceptor.dart';
import 'package:mine_storage/data/models/models.dart';
import 'package:retrofit/retrofit.dart';

part 'user_api.g.dart';

/// The profile row and the email-existence RPC, over PostgREST.
///
/// Auth itself stays on GoTrue: this covers only what is a table read or write.
@RestApi()
abstract class UserApi {
  factory UserApi(Dio dio, {String? baseUrl}) = _UserApi;

  @GET('/rest/v1/users')
  Future<List<UserModel>> fetchUser({
    @Query('id') required String id,
    @Query('select') String select = '*',
  });

  @PATCH('/rest/v1/users')
  Future<void> updateUser(
    @Query('id') String id,
    @Body() UpdateUserRequest request,
  );

  /// Runs before anyone is signed in — signup step 1 and forgot-password both
  /// call it — so it deliberately goes with the anon key.
  @POST('/rest/v1/rpc/email_status')
  @Extra({SupabaseRestInterceptor.requiresAuthKey: false})
  Future<String> emailStatus(@Body() EmailStatusRequest request);
}
