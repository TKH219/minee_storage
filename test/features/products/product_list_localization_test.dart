import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/pages/product_list_page.dart';
import 'package:mine_storage/features/reports/pages/reports_page.dart';
import 'package:mine_storage/features/sales/pages/sales_list_page.dart';
import 'package:mine_storage/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/localization_test_harness.dart';

void main() {
  Widget host(Widget child) => Theme(data: AppTheme.light(), child: child);

  testWidgets('products empty state translates to Vietnamese', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await pumpLocalized(
      tester,
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(_EmptyProductRepository()),
        ],
        child: host(const ProductListPage()),
      ),
      locale: viLocale,
    );
    expect(find.text('Kệ hàng của bạn đang trống'), findsOneWidget);
  });

  testWidgets('reports empty state translates to Vietnamese', (tester) async {
    await pumpLocalized(tester, host(const ReportsPage()), locale: viLocale);
    expect(find.text('Chưa có gì để báo cáo'), findsOneWidget);
  });

  testWidgets('sales empty state translates to Vietnamese', (tester) async {
    await pumpLocalized(tester, host(const SalesListPage()), locale: viLocale);
    expect(find.text('Chưa có đơn nào'), findsOneWidget);
  });
}

class _EmptyProductRepository extends FakeProductRepository {
  _EmptyProductRepository() : super(latency: Duration.zero);

  @override
  Future<PagedProducts> getProducts({
    required ProductFilter filter,
    required int page,
    int limit = 20,
  }) async => const PagedProducts(items: [], hasMore: false);
}
