import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/new/states/sale_cart_state.dart';
import 'package:mine_storage/features/sales/new/states/sale_review_state.dart';
import 'package:mine_storage/features/sales/new/widgets/money_summary.dart';
import 'package:mine_storage/features/sales/new/widgets/sale_buttons.dart';
import 'package:mine_storage/features/sales/new/widgets/sale_metrics.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/coming_soon.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';

/// Measured from the design's S24 frame (`#sale`, node `3321:11591`).
abstract class SaleSuccessMetrics {
  static const double markSize = 92;
  static const double titleSize = 24;
  static const double titleTopGap = 8;
  static const double bodyGap = 12;
  static const double moneyTopGap = 16;
  static const double actionGap = 10;
  static const EdgeInsets actionsPadding = EdgeInsets.fromLTRB(16, 0, 16, 22);
  static const EdgeInsets bodyPadding = EdgeInsets.symmetric(horizontal: 40);
}

/// S24. Stock has moved by the time this screen exists — it is the receipt for
/// a transaction that already landed, not a step on the way to one.
class SaleSuccessPage extends ConsumerStatefulWidget {
  const SaleSuccessPage({super.key});

  @override
  ConsumerState<SaleSuccessPage> createState() => _SaleSuccessPageState();
}

class _SaleSuccessPageState extends ConsumerState<SaleSuccessPage> {
  @override
  void initState() {
    super.initState();
    unawaited(HapticFeedback.mediumImpact());
  }

  @override
  Widget build(BuildContext context) {
    final review = ref.watch(saleReviewStateProvider);
    final sale = review.sale;
    final colors = context.colors;

    if (sale == null) {
      return Scaffold(
        backgroundColor: colors.neutral1,
        body: const SizedBox.shrink(),
      );
    }

    final money = CurrencyFormatter(review.currency);

    return Scaffold(
      backgroundColor: colors.neutral1,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: SaleSuccessMetrics.bodyPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: SaleSuccessMetrics.markSize,
                      height: SaleSuccessMetrics.markSize,
                      child: SuccessCheck(
                        size: SaleSuccessMetrics.markSize,
                        onComplete: () {},
                      ),
                    ),
                    const SizedBox(height: SaleSuccessMetrics.titleTopGap),
                    Text(
                      LocaleKeys.sales_received.tr(
                        namedArgs: {
                          'amount': money.format(sale.totals.buyerTotal),
                        },
                      ),
                      key: const Key('success-received'),
                      textAlign: TextAlign.center,
                      style: context.textStyles.sansTitleHeading2.copyWith(
                        fontSize: SaleSuccessMetrics.titleSize,
                      ),
                    ),
                    const SizedBox(height: SaleSuccessMetrics.bodyGap),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${LocaleKeys.sales_saleCode.tr(namedArgs: {
                              'method': _methodLabel(sale.paymentMethod),
                            })} ',
                          ),
                          TextSpan(
                            text: sale.code,
                            style: context.textStyles.monoBody,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: context.textStyles.sansBody.copyWith(
                        color: colors.neutral6,
                      ),
                    ),
                    const SizedBox(height: SaleSuccessMetrics.moneyTopGap),
                    MoneySummary(
                      profitIsPositive:
                          sale.totals.netProfit >= Decimal.zero,
                      rows: [
                        // Absent for staff, exactly as on the review screen.
                        if (review.showsCostAndProfit)
                          MoneyRow(
                            label: LocaleKeys.sales_netProfit.tr(),
                            value: money.format(sale.totals.netProfit),
                            style: MoneyRowStyle.profit,
                            key: const Key('success-net-profit'),
                          ),
                        MoneyRow(
                          label: LocaleKeys.sales_stockDeducted.tr(),
                          value: sale.deductedLotCount == 1
                              ? LocaleKeys.sales_oneLot.tr()
                              : LocaleKeys.sales_lotsCount.tr(
                                  namedArgs: {
                                    'count': '${sale.deductedLotCount}',
                                  },
                                ),
                          key: const Key('success-stock-deducted'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: SaleSuccessMetrics.actionsPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SalePrimaryButton(
                    key: const Key('success-create-invoice'),
                    label: LocaleKeys.sales_createInvoice.tr(),
                    icon: Icons.receipt_long_outlined,
                    onPressed: showComingSoon,
                  ),
                  const SizedBox(height: SaleSuccessMetrics.actionGap),
                  SaleSecondaryButton(
                    key: const Key('success-new-sale'),
                    label: LocaleKeys.sales_newSale.tr(),
                    onPressed: _startAnother,
                  ),
                  const SizedBox(height: SaleSuccessMetrics.actionGap),
                  TextButton(
                    key: const Key('success-back-to-dashboard'),
                    onPressed: _backToDashboard,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary4,
                      minimumSize: const Size.fromHeight(
                        SaleMetrics.buttonHeight,
                      ),
                      textStyle: context.textStyles.sansBodyBold.copyWith(
                        fontSize: SaleMetrics.buttonTextSize,
                      ),
                    ),
                    child: Text(LocaleKeys.sales_backToDashboard.tr()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A paid sale is finished. Both onward actions clear it so the next one
  /// cannot inherit its lines, its fees, or its payment.
  void _clear() {
    ref.read(saleCartStateProvider.notifier).reset();
    ref.read(saleReviewStateProvider.notifier).reset();
  }

  void _startAnother() {
    _clear();
    context.pushReplacementNamed(AppRoutes.saleNewName);
  }

  void _backToDashboard() {
    _clear();
    context.goNamed(AppRoutes.dashboardName);
  }

  static String _methodLabel(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => LocaleKeys.sales_payCash.tr(),
    PaymentMethod.bankTransfer => LocaleKeys.sales_payBankTransfer.tr(),
    PaymentMethod.card => LocaleKeys.sales_payCard.tr(),
    PaymentMethod.eWallet => LocaleKeys.sales_payEWallet.tr(),
    PaymentMethod.other => LocaleKeys.sales_payOther.tr(),
  };
}
