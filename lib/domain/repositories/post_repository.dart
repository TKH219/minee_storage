import 'package:mine_storage/domain/entities/entities.dart';

/// Demo repository for the reference vertical slice — see [PostEntity].
abstract class PostRepository {
  Future<List<PostEntity>> getPosts({required int page, int limit});
}
