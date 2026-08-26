import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/new/states/product_picker_state.dart';
import 'package:mine_storage/features/sales/new/states/sale_cart_state.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:mine_storage/shared/ui/expiry_badge.dart';
import 'package:mine_storage/shared/ui/loading_circle.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';

import 'product_picker_metrics.dart';

/// S20. Opens on the full list with recently sold on top — no typing needed.
Future<ProductEntity?> showProductPicker(BuildContext context) {
  return showModalBottomSheet<ProductEntity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.neutral0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ProductPickerMetrics.sheetRadius),
      ),
    ),
    builder: (_) => const ProductPickerSheet(),
  );
}

class ProductPickerSheet extends ConsumerStatefulWidget {
  const ProductPickerSheet({super.key});

  @override
  ConsumerState<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<ProductPickerSheet> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(productPickerStateProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productPickerStateProvider);
    final colors = context.colors;

    return FractionallySizedBox(
      heightFactor: ProductPickerMetrics.sheetHeightFactor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: ProductPickerMetrics.sheetPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: ProductPickerMetrics.grabWidth,
                  height: ProductPickerMetrics.grabHeight,
                  margin: const EdgeInsets.only(
                    bottom: ProductPickerMetrics.grabBottomGap,
                  ),
                  decoration: BoxDecoration(
                    color: colors.neutral3,
                    borderRadius: BorderRadius.circular(
                      ProductPickerMetrics.grabHeight / 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ProductPickerMetrics.blockGap),
              _buildSearchRow(context),
              const SizedBox(height: ProductPickerMetrics.blockGap),
              Expanded(child: _buildList(context, state)),
              Padding(
                padding: ProductPickerMetrics.horizontalPadding,
                child: Text(
                  LocaleKeys.sales_pickerNoNegative.tr(),
                  style: context.textStyles.sansCaption.copyWith(
                    color: colors.neutral6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Scan sits *beside* the field, not instead of it: choosing from stock
  /// always works, scanning is the shortcut for when the item is in hand.
  Widget _buildSearchRow(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: ProductPickerMetrics.horizontalPadding,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: ProductPickerMetrics.searchHeight,
              child: TextField(
                controller: _search,
                onChanged: (value) =>
                    ref.read(productPickerStateProvider.notifier).search(value),
                textInputAction: TextInputAction.search,
                style: context.textStyles.sansBody.copyWith(
                  fontSize: ProductPickerMetrics.searchTextSize,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: colors.neutral1,
                  hintText: LocaleKeys.sales_pickerSearchHint.tr(),
                  prefixIcon: Icon(Icons.search_rounded, color: colors.neutral5),
                  contentPadding: ProductPickerMetrics.searchPadding,
                  border: _searchBorder(colors.neutral2),
                  enabledBorder: _searchBorder(colors.neutral2),
                  focusedBorder: _searchBorder(colors.primary4),
                ),
              ),
            ),
          ),
          const SizedBox(width: ProductPickerMetrics.searchRowGap),
          Material(
            color: colors.tintPrimary,
            borderRadius: BorderRadius.circular(
              ProductPickerMetrics.scanButtonRadius,
            ),
            child: InkWell(
              key: const Key('picker-scan-button'),
              onTap: () {},
              borderRadius: BorderRadius.circular(
                ProductPickerMetrics.scanButtonRadius,
              ),
              child: Container(
                width: ProductPickerMetrics.scanButtonSize,
                height: ProductPickerMetrics.scanButtonSize,
                decoration: BoxDecoration(
                  border: Border.all(color: colors.primary2),
                  borderRadius: BorderRadius.circular(
                    ProductPickerMetrics.scanButtonRadius,
                  ),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: colors.primary5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static OutlineInputBorder _searchBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(ProductPickerMetrics.searchRadius),
    borderSide: BorderSide(color: color),
  );

  Widget _buildList(BuildContext context, ProductPickerState state) {
    if (state.isInit || state.isLoading) {
      return const Center(child: LoadingCircle());
    }
    if (state.allProducts.isEmpty && state.recentlySold.isEmpty) {
      return EmptyView(
        icon: Icons.inventory_2_outlined,
        title: state.hasQuery
            ? LocaleKeys.sales_pickerNoMatches.tr(
                namedArgs: {'query': state.query},
              )
            : LocaleKeys.sales_pickerEmptyTitle.tr(),
        subtitle: state.hasQuery ? null : LocaleKeys.sales_pickerEmptyBody.tr(),
      );
    }

    final today = ref.read(nowProvider)();

    return ListView(
      children: [
        if (state.recentlySold.isNotEmpty) ...[
          _SectionHead(label: LocaleKeys.sales_pickerRecentlySold.tr()),
          for (final product in state.recentlySold)
            _ProductRow(product: product, today: today, enabled: state.canPick(product)),
        ],
        _SectionHead(
          label: LocaleKeys.sales_pickerAllProducts.tr(
            namedArgs: {'count': '${state.allProducts.length}'},
          ),
        ),
        for (final product in state.allProducts)
          _ProductRow(product: product, today: today, enabled: state.canPick(product)),
      ],
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ProductPickerMetrics.headPadding,
      child: Text(
        label.toUpperCase(),
        style: context.textStyles.sansCaption.copyWith(
          fontSize: ProductPickerMetrics.headTextSize,
          fontWeight: FontWeight.w600,
          letterSpacing: ProductPickerMetrics.headSpacing,
          color: context.colors.neutral6,
        ),
      ),
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({
    required this.product,
    required this.today,
    required this.enabled,
  });

  final ProductEntity product;
  final DateTime today;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final texts = context.textStyles;
    final money = CurrencyFormatter(ref.watch(saleCartStateProvider).currency);

    final row = InkWell(
      key: Key('picker-row-${product.id}'),
      onTap: enabled ? () => Navigator.of(context).pop(product) : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.neutral2)),
        ),
        padding: ProductPickerMetrics.rowPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: ProductPickerMetrics.thumbSize,
              height: ProductPickerMetrics.thumbSize,
              decoration: BoxDecoration(
                color: colors.neutral2,
                borderRadius: BorderRadius.circular(
                  ProductPickerMetrics.thumbRadius,
                ),
              ),
              child: Icon(Icons.inventory_2_outlined, color: colors.neutral5),
            ),
            const SizedBox(width: ProductPickerMetrics.rowGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: texts.sansBodyBold.copyWith(
                            fontSize: ProductPickerMetrics.nameSize,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.latestUnitPrice != null)
                        Text(
                          money.format(product.latestUnitPrice!),
                          style: texts.monoBody.copyWith(
                            fontSize: ProductPickerMetrics.priceSize,
                            color: colors.neutral7,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: ProductPickerMetrics.rowBottomGap),
                  Row(
                    children: [
                      Text(
                        LocaleKeys.sales_pickerLeft.tr(
                          namedArgs: {
                            'quantity': formatQuantity(product.totalRemaining),
                          },
                        ),
                        style: texts.monoBody.copyWith(
                          fontSize: ProductPickerMetrics.quantitySize,
                          fontWeight: FontWeight.w500,
                          color: enabled ? colors.neutral8 : colors.neutral5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: enabled
                            ? ExpiryBadge(
                                status: product.statusOn(today),
                                expiry: product.nearestExpiry,
                                today: today,
                              )
                            : const _OutOfStockBadge(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return enabled
        ? row
        : Opacity(
            opacity: ProductPickerMetrics.outOfStockOpacity,
            child: row,
          );
  }
}

class _OutOfStockBadge extends StatelessWidget {
  const _OutOfStockBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: ProductPickerMetrics.badgeHeight,
      padding: ProductPickerMetrics.badgePadding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.neutral2,
        borderRadius: BorderRadius.circular(ProductPickerMetrics.badgeRadius),
      ),
      child: Text(
        LocaleKeys.sales_pickerOutOfStock.tr(),
        style: context.textStyles.sansCaption.copyWith(
          fontSize: ProductPickerMetrics.badgeTextSize,
          fontWeight: FontWeight.w600,
          color: colors.neutral5,
        ),
      ),
    );
  }
}
