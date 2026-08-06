import 'package:mine_storage/core/constants.dart';
import 'package:mine_storage/data/data_sources/remote/post_api.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl({required this.postApi});

  final PostApi postApi;

  @override
  Future<List<PostEntity>> getPosts({
    required int page,
    int limit = Constants.defaultPageSize,
  }) async {
    final models = await postApi.getPosts(page: page, limit: limit);
    return models.map((model) => model.toEntity()).toList();
  }
}
