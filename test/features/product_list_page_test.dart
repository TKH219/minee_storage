import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/features/products/pages/product_list_page.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:mine_storage/shared/ui/app_filter_chip.dart';
import 'package:mine_storage/shared/ui/error_aware_container.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';
import 'package:mine_storage/shared/ui/product_row.dart';

import '../support/localization_test_harness.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    useLocale();
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Future<void> pump(WidgetTester tester, ProductRepository repository) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          productRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const ProductListPage()),
      ),
    );
  }

  testWidgets('shows skeleton rows while the first page loads', (tester) async {
    // Deliberately latent so the loading state is observable. Never
    // pumpAndSettle here: the shimmer animates forever.
    await pump(tester, FakeProductRepository(latency: const Duration(seconds: 1)));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SkeletonRow), findsWidgets);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('renders a row per product once loaded', (tester) async {
    await pump(tester, FakeProductRepository(latency: Duration.zero));
    await tester.pumpAndSettle();

    expect(find.byType(ProductRow), findsWidgets);
    expect(find.byType(ErrorAwareContainer), findsNothing);
  });

  testWidgets('shows the empty view when nothing matches', (tester) async {
    await pump(tester, _EmptyRepository());
    await tester.pumpAndSettle();

    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.byType(ProductRow), findsNothing);
  });

  testWidgets('shows a retryable error surface when the first load fails', (tester) async {
    await pump(tester, _FailingRepository());
    await tester.pumpAndSettle();

    expect(find.byType(ErrorAwareContainer), findsOneWidget);
    expect(find.text('offline'), findsOneWidget);
  });

  testWidgets('renders the four quick filter chips', (tester) async {
    await pump(tester, FakeProductRepository(latency: Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Expiring soon'), findsWidgets);
    expect(find.text('Expired'), findsWidgets);
    expect(find.text('Archived'), findsOneWidget);
  });

  testWidgets('tapping a quick filter chip reloads with that filter', (tester) async {
    final repository = _RecordingRepository();
    await pump(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppFilterChip, 'Archived'));
    await tester.pumpAndSettle();

    expect(repository.lastFilter?.quickFilter, ProductQuickFilter.archived);
  });

  testWidgets('search is debounced rather than firing per keystroke', (tester) async {
    final repository = _RecordingRepository();
    await pump(tester, repository);
    await tester.pumpAndSettle();
    final before = repository.callCount;

    await tester.enterText(find.byType(TextField), 'oli');
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.callCount, before);

    // A pending Timer schedules no frames, so pumpAndSettle alone would return
    // without ever firing the debounce.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(repository.callCount, before + 1);
    expect(repository.lastFilter?.query, 'oli');
  });
}

class _EmptyRepository extends FakeProductRepository {
  _EmptyRepository() : super(latency: Duration.zero);

  @override
  Future<PagedProducts> getProducts({
    required ProductFilter filter,
    required int page,
    int limit = 20,
  }) async => const PagedProducts(items: [], hasMore: false);
}

class _FailingRepository extends FakeProductRepository {
  _FailingRepository() : super(latency: Duration.zero);

  @override
  Future<PagedProducts> getProducts({
    required ProductFilter filter,
    required int page,
    int limit = 20,
  }) async => throw const NetworkException(message: 'offline');
}

class _RecordingRepository extends FakeProductRepository {
  _RecordingRepository() : super(latency: Duration.zero);

  ProductFilter? lastFilter;
  int callCount = 0;

  @override
  Future<PagedProducts> getProducts({
    required ProductFilter filter,
    required int page,
    int limit = 20,
  }) async {
    lastFilter = filter;
    callCount++;
    return super.getProducts(filter: filter, page: page, limit: limit);
  }
}
