import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:mine_storage/data/models/models.dart';

part 'post_api.g.dart';

/// Demo API for the reference vertical slice.
///
/// jsonplaceholder returns a bare JSON array rather than the `{code, message,
/// data}` envelope, so this does not use [BaseResponse]. Real Mine Storage
/// endpoints should return `Future<BaseResponse<T>>` instead.
@RestApi()
abstract class PostApi {
  factory PostApi(Dio dio, {String? baseUrl}) = _PostApi;

  @GET('/posts')
  Future<List<PostModel>> getPosts({
    @Query('_page') required int page,
    @Query('_limit') required int limit,
  });
}
