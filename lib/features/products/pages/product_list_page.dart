import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/product_list_state.dart';
import 'package:mine_storage/features/products/widgets/product_filter_sheet.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_filter_chip.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:mine_storage/shared/ui/error_aware_container.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';
import 'package:mine_storage/shared/ui/product_row.dart';

String _quickFilterLabel(ProductQuickFilter filter) => switch (filter) {
  ProductQuickFilter.all => LocaleKeys.products_filterAll.tr(),
  ProductQuickFilter.expiringSoon => LocaleKeys.products_filterExpiringSoon.tr(),
  ProductQuickFilter.expired => LocaleKeys.products_filterExpired.tr(),
  ProductQuickFilter.archived => LocaleKeys.products_filterArchived.tr(),
};

class ProductListPage extends BasePage {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState
    extends BasePageState<ProductListPage, ProductListState, ProductListStateNotifier> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    // The list renders its own skeleton rows, so the blocking overlay would
    // only dim an empty scaffold.
    allowToShowLoading = false;
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      notifier.loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => notifier.search(value));
  }

  @override
  void setCurrentState() => currentState = ref.watch(productListStateProvider);

  @override
  void setNotifier() => notifier = ref.read(productListStateProvider.notifier);

  @override
  void initDataFromConstructor() {
    notifier
      ..loadInitial()
      ..loadCategories();
  }

  Future<void> _createProduct() async {
    final created = await context.pushNamed<String>(AppRoutes.productNewName);
    if (created != null && mounted) await notifier.refresh();
  }

  Future<void> _openProduct(String id) async {
    await context.pushNamed<void>(
      AppRoutes.productDetailName,
      pathParameters: {'id': id},
    );
    // Detail can archive, receive or consume, so the list is always restated.
    if (mounted) await notifier.refresh();
  }

  Future<void> _openFilters() async {
    final result = await ProductFilterSheet.show(
      context,
      current: currentState.filter,
      categories: currentState.categories,
    );
    if (result != null) await notifier.applyFilter(result);
  }

  @override
  Widget buildPageContent(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral1,
      appBar: AppBar(title: Text(LocaleKeys.products_title.tr())),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('product-add-fab'),
        onPressed: _createProduct,
        icon: const Icon(Icons.add_rounded),
        label: Text(LocaleKeys.products_addTitle.tr()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchRow(context),
            _buildQuickFilters(context),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: LocaleKeys.products_searchHint.tr(),
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: currentState.filter.hasActiveFilters,
            child: IconButton.filledTonal(
              icon: const Icon(Icons.tune_rounded),
              onPressed: _openFilters,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final filter in ProductQuickFilter.values) ...[
            Center(
              child: AppFilterChip(
                label: _quickFilterLabel(filter),
                selected: currentState.filter.quickFilter == filter,
                onTap: () => notifier.setQuickFilter(filter),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (currentState.isLoading && currentState.products.isEmpty) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => const SkeletonRow(),
      );
    }

    if (currentState.showFullScreenError) {
      return ErrorAwareContainer(
        message: currentState.errorMessage ??
            (currentState.errorMessageKey ?? LocaleKeys.errors_generic).tr(),
        onRetry: notifier.loadInitial,
      );
    }

    if (currentState.isEmpty) {
      return EmptyView(
        icon: Icons.inventory_2_outlined,
        title: LocaleKeys.products_emptyTitle.tr(),
        subtitle: LocaleKeys.products_emptySubtitle.tr(),
        actionLabel: LocaleKeys.common_tryAgain.tr(),
        onAction: notifier.loadInitial,
      );
    }

    final today = ref.watch(nowProvider)();

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: currentState.products.length + (currentState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= currentState.products.length) return const SkeletonRow();
          final product = currentState.products[index];
          return ProductRow(
            product: product,
            today: today,
            onTap: () => _openProduct(product.id),
          );
        },
      ),
    );
  }
}
