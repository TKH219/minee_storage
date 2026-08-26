import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

/// Measured from the design's `.paygrid` / `.paybtn`.
abstract class PaymentGridMetrics {
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 16);
  static const double gap = 8;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 12);
  static const double buttonRadius = 12;
  static const double borderWidth = 1.5;
  static const double innerGap = 6;
  static const double labelSize = 13;
  static const double iconSize = 22;
}

/// How the cash arrived. It changes no figure — it is what makes "how much
/// came through the bank this month" answerable.
class PaymentMethodGrid extends StatelessWidget {
  const PaymentMethodGrid({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    const methods = PaymentMethod.values;

    return Padding(
      padding: PaymentGridMetrics.padding,
      child: Column(
        children: [
          for (var row = 0; row < methods.length; row += 2) ...[
            if (row > 0) const SizedBox(height: PaymentGridMetrics.gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _button(context, methods[row])),
                  const SizedBox(width: PaymentGridMetrics.gap),
                  Expanded(child: _button(context, methods[row + 1])),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _button(BuildContext context, PaymentMethod method) {
    final colors = context.colors;
    final isSelected = method == selected;

    return InkWell(
      key: Key('payment-${method.name}'),
      onTap: () => onChanged(method),
      borderRadius: BorderRadius.circular(PaymentGridMetrics.buttonRadius),
      child: Container(
        padding: PaymentGridMetrics.buttonPadding,
        decoration: BoxDecoration(
          color: isSelected ? colors.tintPrimary : null,
          border: Border.all(
            color: isSelected ? colors.inkPrimary : colors.neutral3,
            width: PaymentGridMetrics.borderWidth,
          ),
          borderRadius: BorderRadius.circular(PaymentGridMetrics.buttonRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconFor(method),
              size: PaymentGridMetrics.iconSize,
              color: isSelected ? colors.primary5 : colors.neutral7,
            ),
            const SizedBox(height: PaymentGridMetrics.innerGap),
            Text(
              _labelFor(method),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.sansBody.copyWith(
                fontSize: PaymentGridMetrics.labelSize,
                fontWeight: FontWeight.w500,
                color: isSelected ? colors.primary5 : colors.neutral7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => Icons.payments_outlined,
    PaymentMethod.bankTransfer => Icons.account_balance_outlined,
    PaymentMethod.card => Icons.credit_card_rounded,
    PaymentMethod.eWallet => Icons.account_balance_wallet_outlined,
  };

  static String _labelFor(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => LocaleKeys.sales_payCash.tr(),
    PaymentMethod.bankTransfer => LocaleKeys.sales_payBankTransfer.tr(),
    PaymentMethod.card => LocaleKeys.sales_payCard.tr(),
    PaymentMethod.eWallet => LocaleKeys.sales_payEWallet.tr(),
  };
}
