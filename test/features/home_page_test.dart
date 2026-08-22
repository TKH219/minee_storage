import '../support/fake_store_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/post_repository.dart';
import 'package:mine_storage/features/home/pages/home_page.dart';
import 'package:mine_storage/features/home/widgets/post_item.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:mine_storage/shared/ui/error_aware_container.dart';

import '../support/auth_test_harness.dart';
import '../support/fake_auth_repository.dart';

import '../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Future<void> pumpHome(WidgetTester tester, PostRepository repository) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          postRepositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          storeRepositoryProvider.overrideWithValue(
            FakeStoreRepository(stores: [storeFixture()]),
          ),
          routerProvider.overrideWithValue(buildTestRouter()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HomePage(),
        ),
      ),
    );
  }

  testWidgets('shows a spinner while the first page is loading', (tester) async {
    await pumpHome(tester, _FakePostRepository(delay: const Duration(seconds: 1)));

    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PostItem), findsNothing);

    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('renders a list once posts load', (tester) async {
    await pumpHome(
      tester,
      _FakePostRepository(
        posts: const [
          PostEntity(id: 1, userId: 1, title: 'alpha', body: 'first body'),
          PostEntity(id: 2, userId: 1, title: 'beta', body: 'second body'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PostItem), findsNWidgets(2));
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.byType(ErrorAwareContainer), findsNothing);
  });

  testWidgets('shows the empty view when the api returns nothing', (tester) async {
    await pumpHome(tester, _FakePostRepository(posts: const []));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.byType(PostItem), findsNothing);
  });

  testWidgets('shows a retryable error surface when the first load fails', (tester) async {
    final repository = _FakePostRepository(
      error: const NetworkException(message: 'No connection'),
    );
    await pumpHome(tester, repository);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorAwareContainer), findsOneWidget);
    expect(find.text('No connection'), findsOneWidget);

    repository
      ..error = null
      ..posts = const [PostEntity(id: 1, userId: 1, title: 'recovered', body: 'body')];

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorAwareContainer), findsNothing);
    expect(find.byType(PostItem), findsOneWidget);
  });
}

class _FakePostRepository implements PostRepository {
  _FakePostRepository({
    this.posts = const [],
    this.error,
    this.delay = Duration.zero,
  });

  List<PostEntity> posts;
  Object? error;
  Duration delay;

  @override
  Future<List<PostEntity>> getPosts({required int page, int limit = 20}) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (error != null) throw error!;
    return posts;
  }
}
