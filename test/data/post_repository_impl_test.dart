import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/data_sources/remote/post_api.dart';
import 'package:mine_storage/data/models/models.dart';
import 'package:mine_storage/data/repositories/post_repository_impl.dart';

import '../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  test('maps every model to an entity, preserving order', () async {
    final repository = PostRepositoryImpl(
      postApi: _FakePostApi(
        result: [
          const PostModel(id: 1, userId: 9, title: 'first', body: 'a'),
          const PostModel(id: 2, userId: 9, title: 'second', body: 'b'),
        ],
      ),
    );

    final posts = await repository.getPosts(page: 1);

    expect(posts, hasLength(2));
    expect(posts.first.id, 1);
    expect(posts.first.title, 'first');
    expect(posts.last.id, 2);
  });

  test('forwards paging arguments to the api', () async {
    final api = _FakePostApi(result: const []);
    final repository = PostRepositoryImpl(postApi: api);

    await repository.getPosts(page: 3, limit: 50);

    expect(api.lastPage, 3);
    expect(api.lastLimit, 50);
  });

  test('lets data-layer exceptions propagate untouched', () async {
    final repository = PostRepositoryImpl(
      postApi: _FakePostApi(error: const NetworkException(message: 'offline')),
    );

    expect(
      () => repository.getPosts(page: 1),
      throwsA(isA<NetworkException>()),
    );
  });
}

class _FakePostApi implements PostApi {
  _FakePostApi({this.result, this.error});

  final List<PostModel>? result;
  final Object? error;

  int? lastPage;
  int? lastLimit;

  @override
  Future<List<PostModel>> getPosts({required int page, required int limit}) async {
    lastPage = page;
    lastLimit = limit;
    if (error != null) throw error!;
    return result ?? const [];
  }
}
