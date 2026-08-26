import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/sales/new/states/sale_cart_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/error_aware_container.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';

import '../widgets/allocation_sheet.dart';
import '../widgets/cart_line_row.dart';
import '../widgets/cart_metrics.dart';
import '../widgets/fees_sheet.dart';
import '../widgets/money_summary.dart';
import '../widgets/product_picker_sheet.dart';
import '../widgets/sale_buttons.dart';
import '../widgets/sale_metrics.dart';

/// S19. The basket, and the empty state that starts every sale.
class SaleCartPage extends BasePage {
  const SaleCartPage({super.key});

  @override
  ConsumerState<SaleCartPage> createState() => _SaleCartPageState();
}

class _SaleCartPageState
    extends BasePageState<SaleCartPage, SaleCartState, SaleCartStateNotifier> {
  @override
  void initState() {
    allowToShowLoading = false;
    super.initState();
  }

  @override
  void setCurrentState() => currentState = ref.watch(saleCartStateProvider);

  @override
  void setNotifier() => notifier = ref.read(saleCartStateProvider.notifier);

  @override
  void initDataFromConstructor() => notifier.load();

  @override
  Widget buildPageContent(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.neutral1,
      appBar: AppBar(
        toolbarHeight: SaleMetrics.appBarHeight,
        backgroundColor: colors.neutral0,
        leading: const BackButton(),
        title: Text(
          LocaleKeys.sales_newTitle.tr(),
          style: context.textStyles.sansBodyBold.copyWith(
            fontSize: SaleMetrics.appBarTitleSize,
          ),
        ),
        actions: [
          if (!currentState.isEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  _lineCountLabel(),
                  style: context.textStyles.sansCaption.copyWith(
                    color: colors.neutral6,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.neutral2),
        ),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  String _lineCountLabel() {
    final count = currentState.draft.lines.length;
    return count == 1
        ? LocaleKeys.sales_oneLine.tr()
        : LocaleKeys.sales_lineCount.tr(namedArgs: {'count': '$count'});
  }

  Widget _buildBody(BuildContext context) {
    if (currentState.isError) {
      return ErrorAwareContainer(
        message: currentState.errorMessage ??
            (currentState.errorMessageKey ?? LocaleKeys.errors_generic).tr(),
        onRetry: notifier.load,
      );
    }
    if (currentState.isEmpty) return _buildEmptyCart(context);
    return _buildBasket(context);
  }

  Widget _buildBasket(BuildContext context) {
    final money = CurrencyFormatter(currentState.currency);
    final draft = currentState.draft;
    final totals = draft.totals;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (var index = 0; index < draft.lines.length; index++)
                CartLineRow(
                  line: draft.lines[index],
                  money: money,
                  onEdit: () => _editLine(index),
                  onRemove: () => notifier.removeLine(index),
                ),
              Padding(
                padding: CartMetrics.addLinePadding,
                child: SaleSecondaryButton(
                  key: const Key('cart-add-another-line'),
                  label: LocaleKeys.sales_addAnotherLine.tr(),
                  icon: Icons.add_rounded,
                  small: true,
                  onPressed: _chooseProduct,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CartMetrics.moneyTopGap),
        MoneySummary(
          rows: [
            MoneyRow(
              label: LocaleKeys.sales_itemsSubtotal.tr(),
              value: money.format(totals.itemsSubtotal),
              key: const Key('cart-items-subtotal'),
            ),
            MoneyRow(
              label: LocaleKeys.sales_feesAndDiscounts.tr(),
              value: money.format(totals.feesAndDiscounts),
              key: const Key('cart-fees-and-discounts'),
              onTap: _editFees,
            ),
            MoneyRow(
              label: LocaleKeys.sales_buyerPays.tr(),
              value: money.format(totals.buyerTotal),
              style: MoneyRowStyle.total,
              key: const Key('cart-buyer-pays'),
            ),
          ],
        ),
        Padding(
          padding: CartMetrics.payPadding,
          child: SalePrimaryButton(
            key: const Key('cart-review-and-pay'),
            label: LocaleKeys.sales_reviewAndPay.tr(),
            onPressed: currentState.isEmpty ? null : _reviewAndPay,
          ),
        ),
      ],
    );
  }

  /// The split link leads back into the allocation that produced it, with the
  /// line's own quantity and price already filled in.
  Future<void> _editLine(int index) async {
    final line = currentState.draft.lines[index];
    final product = await ref
        .read(productRepositoryProvider)
        .getProduct(line.productId, storeId: currentState.storeId!);
    if (!mounted) return;

    final replacement = await showAllocationSheet(
      context,
      product: product,
      quantity: line.quantity,
      sellPrice: line.unitSellPrice,
    );
    if (replacement == null || !mounted) return;
    notifier.replaceLine(index, replacement);
  }

  Future<void> _editFees() async {
    final fees = await showFeesSheet(
      context,
      itemsSubtotal: currentState.draft.itemsSubtotal,
      fees: currentState.draft.fees,
      currency: currentState.currency,
    );
    if (fees == null || !mounted) return;
    notifier.setFees(fees);
  }

  void _reviewAndPay() {}

  Widget _buildEmptyCart(BuildContext context) {
    final colors = context.colors;
    final texts = context.textStyles;

    return Padding(
      padding: SaleMetrics.emptyPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: SaleMetrics.emptyArtSize,
              height: SaleMetrics.emptyArtSize,
              margin: const EdgeInsets.only(bottom: SaleMetrics.emptyArtBottomGap),
              decoration: BoxDecoration(
                color: colors.neutral1,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_basket_outlined,
                size: SaleMetrics.emptyArtIconSize,
                color: colors.neutral4,
              ),
            ),
          ),
          const SizedBox(height: SaleMetrics.emptyGap),
          Text(
            LocaleKeys.sales_cartEmptyTitle.tr(),
            textAlign: TextAlign.center,
            style: texts.sansBodyBold.copyWith(
              fontSize: SaleMetrics.emptyTitleSize,
              color: colors.neutral9,
            ),
          ),
          const SizedBox(height: SaleMetrics.emptyGap),
          Text(
            LocaleKeys.sales_cartEmptyBody.tr(),
            textAlign: TextAlign.center,
            style: texts.sansBody.copyWith(
              fontSize: SaleMetrics.emptyBodySize,
              height: 1.5,
              color: colors.neutral6,
            ),
          ),
          const SizedBox(
            height: SaleMetrics.emptyGap + SaleMetrics.emptyPrimaryTopGap,
          ),
          SalePrimaryButton(
            key: const Key('sale-choose-products'),
            label: LocaleKeys.sales_chooseFromProducts.tr(),
            icon: Icons.inventory_2_outlined,
            padding: SaleMetrics.wideButtonPadding,
            onPressed: _chooseProduct,
          ),
          const SizedBox(height: SaleMetrics.emptyGap),
          SaleSecondaryButton(
            key: const Key('sale-scan-barcode'),
            label: LocaleKeys.sales_scanBarcode.tr(),
            icon: Icons.qr_code_scanner_rounded,
            padding: SaleMetrics.wideButtonPadding,
            onPressed: _scanBarcode,
          ),
        ],
      ),
    );
  }

  /// Product, then quantity — never a lot. The split falls out of the
  /// allocation sheet, which resolves it through the repository.
  Future<void> _chooseProduct() async {
    final product = await showProductPicker(context);
    if (product == null || !mounted) return;

    final line = await showAllocationSheet(context, product: product);
    if (line == null || !mounted) return;

    notifier.addLine(line);
  }

  void _scanBarcode() {}
}
