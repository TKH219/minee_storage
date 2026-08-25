import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/detail/states/product_detail_state.dart';
import 'package:mine_storage/features/products/detail/widgets/consume_sheet.dart';
import 'package:mine_storage/features/products/detail/widgets/lot_sheet.dart';
import 'package:mine_storage/features/products/detail/widgets/other_stores_section.dart';
import 'package:mine_storage/features/settings/states/settings_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_snack.dart';
import 'package:mine_storage/shared/ui/error_aware_container.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';
import 'package:mine_storage/shared/ui/lot_card.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';

class ProductDetailPage extends BasePage {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState
    extends BasePageState<ProductDetailPage, ProductDetailState, ProductDetailStateNotifier> {
  @override
  void initState() {
    allowToShowLoading = false;
    super.initState();
  }

  @override
  void setCurrentState() => currentState = ref.watch(productDetailStateProvider);

  @override
  void setNotifier() => notifier = ref.read(productDetailStateProvider.notifier);

  @override
  void initDataFromConstructor() => notifier.load(widget.productId);

  Future<void> _receiveStock({ProductBatchEntity? batch}) async {
    final product = currentState.product;
    if (product == null) return;

    final saved = await LotSheet.show(context, product: product, batch: batch);
    if (saved == true && mounted) await notifier.load(widget.productId);
  }

  Future<void> _useStock() async {
    final product = currentState.product;
    if (product == null) return;

    final used = await ConsumeSheet.show(context, product: product);
    if (used == true && mounted) {
      await notifier.load(widget.productId);
      if (mounted) showSuccessSnack(LocaleKeys.products_usedSuccess.tr());
    }
  }

  Future<void> _archive() async {
    final product = currentState.product;
    if (product == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          LocaleKeys.products_archiveDialogTitle.tr(namedArgs: {'name': product.name}),
        ),
        // Naming the quantity is the point: archiving stock is not the same
        // decision as archiving something already empty.
        content: Text(
          LocaleKeys.products_archiveDialogBody.tr(
            namedArgs: {'qty': formatQuantity(product.totalRemaining)},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(LocaleKeys.common_cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(LocaleKeys.products_archiveProduct.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await notifier.archive();
    if (!mounted) return;
    showUndoSnack(
      LocaleKeys.products_archivedSnack.tr(),
      actionLabel: LocaleKeys.products_undo.tr(),
      onAction: notifier.restore,
    );
  }

  @override
  Widget buildPageContent(BuildContext context) {
    final colors = context.colors;
    final product = currentState.product;

    return Scaffold(
      backgroundColor: colors.neutral1,
      appBar: AppBar(title: Text(product?.name ?? '')),
      body: SafeArea(
        child: switch (currentState) {
          final s when s.isError && s.product == null => ErrorAwareContainer(
            message: s.errorMessage ?? (s.errorMessageKey ?? LocaleKeys.errors_generic).tr(),
            onRetry: () => notifier.load(widget.productId),
          ),
          final s when s.product == null => ListView.builder(
            itemCount: 4,
            itemBuilder: (context, index) => const SkeletonRow(),
          ),
          _ => _buildLoaded(context, product!),
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, ProductEntity product) {
    final colors = context.colors;
    final today = ref.watch(nowProvider)();
    final lots = currentState.orderedBatches;
    final nextOut = currentState.nextOut;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (product.archived)
          Container(
            key: const Key('archived-banner'),
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.neutral2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              LocaleKeys.products_archivedBanner.tr(),
              style: context.textStyles.sansCaption.copyWith(color: colors.neutral7),
            ),
          ),
        _Header(product: product, today: today),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('use-stock-button'),
                  onPressed: currentState.canUseStock ? _useStock : null,
                  child: Text(LocaleKeys.products_useStock.tr()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  key: const Key('add-lot-button'),
                  onPressed: product.archived ? null : () => _receiveStock(),
                  child: Text(LocaleKeys.products_addLot.tr()),
                ),
              ),
            ],
          ),
        ),
        if (product.archived)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              key: const Key('restore-button'),
              onPressed: notifier.restore,
              child: Text(LocaleKeys.products_restoreProduct.tr()),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              key: const Key('archive-button'),
              onPressed: _archive,
              child: Text(
                LocaleKeys.products_archiveProduct.tr(),
                style: context.textStyles.sansBodyBold.copyWith(color: colors.red5),
              ),
            ),
          ),
        const SizedBox(height: 8),
        OtherStoresSection(holdings: currentState.otherStores),
        const SizedBox(height: 16),
        if (lots.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.products_noStockTitle.tr(),
                  style: context.textStyles.sansBodyBold,
                ),
                const SizedBox(height: 6),
                Text(
                  LocaleKeys.products_noStockSubtitle.tr(),
                  style: context.textStyles.sansCaption.copyWith(color: colors.neutral6),
                ),
              ],
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              lots.length == 1
                  ? LocaleKeys.products_oneLot.tr()
                  : LocaleKeys.products_lotsCount.tr(
                      namedArgs: {'count': '${lots.length}'},
                    ),
              style: context.textStyles.sansCaption.copyWith(color: colors.neutral6),
            ),
          ),
          const SizedBox(height: 8),
          for (final lot in lots)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GestureDetector(
                onTap: product.archived ? null : () => _receiveStock(batch: lot),
                child: LotCard(
                  lot: lot,
                  isNextOut: nextOut != null && lot.id == nextOut.id,
                  today: today,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// The three derived figures. None is stored; each is computed from the batches
/// held in the store being viewed.
final _shortDate = DateFormat('d MMM y');

class _Header extends ConsumerWidget {
  const _Header({required this.product, required this.today});

  final ProductEntity product;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(currencyFormatterProvider);
    final price = product.latestUnitPrice;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Figure(
              label: LocaleKeys.products_remaining.tr(),
              value: formatQuantity(product.totalRemaining),
            ),
          ),
          Expanded(
            child: _Figure(
              label: LocaleKeys.products_nearestExpiry.tr(),
              // The design shows this as a figure, not a pill — the pill is the
              // list row's job. A depleted product reads "—", and one whose
              // lots carry no date reads "Not tracked".
              value: switch (product) {
                final p when !p.hasStock => '—',
                final p when p.nearestExpiry == null =>
                  LocaleKeys.stock_notTracked.tr(),
                final p => _shortDate.format(p.nearestExpiry!),
              },
            ),
          ),
          Expanded(
            child: _Figure(
              label: LocaleKeys.products_latestPrice.tr(),
              value: price == null ? '—' : money.format(price),
            ),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textStyles.sansCaption.copyWith(color: context.colors.neutral6),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.textStyles.monoBody.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
