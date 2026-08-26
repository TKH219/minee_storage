import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/new/states/sale_cart_state.dart';
import 'package:mine_storage/features/sales/new/states/sale_review_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_snack.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';

import '../widgets/cart_metrics.dart';
import '../widgets/money_summary.dart';
import '../widgets/payment_method_grid.dart';
import '../widgets/sale_buttons.dart';
import '../widgets/sale_metrics.dart';

/// S23. Both truths on one screen for an owner — what the buyer hands over,
/// and what the store actually keeps. Staff see only the first.
class SaleReviewPage extends BasePage {
  const SaleReviewPage({super.key});

  @override
  ConsumerState<SaleReviewPage> createState() => _SaleReviewPageState();
}

class _SaleReviewPageState
    extends BasePageState<SaleReviewPage, SaleReviewState, SaleReviewStateNotifier> {
  @override
  void setCurrentState() => currentState = ref.watch(saleReviewStateProvider);

  @override
  void setNotifier() => notifier = ref.read(saleReviewStateProvider.notifier);

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
          LocaleKeys.sales_reviewTitle.tr(),
          style: context.textStyles.sansBodyBold.copyWith(
            fontSize: SaleMetrics.appBarTitleSize,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.neutral2),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 10),
                children: [
                  MoneySummary(
                    rows: _moneyRows(context),
                    profitIsPositive:
                        currentState.totals.netProfit >= Decimal.zero,
                  ),
                  if (!currentState.showsCostAndProfit) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: MoneySummaryMetrics.padding,
                      child: const _RoleLock(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Padding(
                    padding: MoneySummaryMetrics.padding,
                    child: Text(
                      LocaleKeys.sales_paymentMethod.tr().toUpperCase(),
                      style: context.textStyles.sansCaption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.09 * 11,
                        color: colors.neutral6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PaymentMethodGrid(
                    selected: currentState.paymentMethod,
                    onChanged: ref
                        .read(saleCartStateProvider.notifier)
                        .setPaymentMethod,
                  ),
                ],
              ),
            ),
            Padding(
              padding: CartMetrics.payPadding,
              child: SalePrimaryButton(
                key: const Key('review-confirm-payment'),
                label: LocaleKeys.sales_confirmPayment.tr(),
                onPressed: currentState.canConfirm ? _confirm : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The staff rows are absent from this list, not hidden by it — there is no
  /// widget to un-blur.
  List<MoneyRow> _moneyRows(BuildContext context) {
    final money = CurrencyFormatter(currentState.currency);
    final totals = currentState.totals;

    return [
      MoneyRow(
        label: LocaleKeys.sales_itemsSubtotal.tr(),
        value: money.format(totals.itemsSubtotal),
        key: const Key('review-items-subtotal'),
      ),
      for (final fee in totals.fees)
        MoneyRow(
          label: fee.fee.name,
          value: _signed(money, fee),
          style: fee.fee.direction == FeeDirection.discount
              ? MoneyRowStyle.negative
              : MoneyRowStyle.plain,
          note: fee.fee.direction == FeeDirection.passThrough
              ? LocaleKeys.sales_remittedYouKeepNone.tr()
              : null,
          key: Key('review-fee-${fee.fee.id}'),
        ),
      MoneyRow(
        label: LocaleKeys.sales_buyerPays.tr(),
        value: money.format(totals.buyerTotal),
        style: MoneyRowStyle.total,
        key: const Key('review-buyer-pays'),
      ),
      if (currentState.showsCostAndProfit) ...[
        MoneyRow(
          label: LocaleKeys.sales_lessPassThrough.tr(),
          value: '−${money.format(totals.lessPassThroughAndCosts)}',
          style: MoneyRowStyle.subtotalRule,
          key: const Key('review-less-pass-through'),
        ),
        MoneyRow(
          label: LocaleKeys.sales_netRevenue.tr(),
          value: money.format(totals.netRevenue),
          key: const Key('review-net-revenue'),
        ),
        MoneyRow(
          label: LocaleKeys.sales_costOfGoods.tr(),
          value: '−${money.format(totals.cogs)}',
          key: const Key('review-cost-of-goods'),
        ),
        MoneyRow(
          label: LocaleKeys.sales_netProfitMargin.tr(
            namedArgs: {'margin': _marginLabel(totals)},
          ),
          value: money.format(totals.netProfit),
          style: MoneyRowStyle.profit,
          key: const Key('review-net-profit'),
        ),
      ],
    ];
  }

  static String _signed(CurrencyFormatter money, ComputedFee fee) {
    final takesAway = fee.fee.direction == FeeDirection.discount;
    return '${takesAway ? '−' : '+'}${money.format(fee.amount)}';
  }

  static String _marginLabel(SaleTotals totals) =>
      (totals.netMargin * Decimal.fromInt(100)).round(scale: 1).toString();

  Future<void> _confirm() async {
    await notifier.confirm();
    if (!mounted) return;

    final sale = ref.read(saleReviewStateProvider).sale;
    if (sale == null) {
      final state = ref.read(saleReviewStateProvider);
      showErrorSnack(
        state.errorMessage ??
            (state.errorMessageKey ?? LocaleKeys.errors_generic).tr(),
      );
      return;
    }
    context.pushReplacementNamed(
      AppRoutes.saleSuccessName,
      pathParameters: {'id': sale.id},
    );
  }
}

class _RoleLock extends StatelessWidget {
  const _RoleLock();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: colors.neutral1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.neutral3),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: colors.neutral6),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              LocaleKeys.sales_roleLocked.tr(),
              style: context.textStyles.sansBody.copyWith(
                fontSize: 12.5,
                color: colors.neutral6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
