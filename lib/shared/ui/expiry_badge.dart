import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/domain/entities/expiry_status.dart';

/// The one piece of colour in the app that carries meaning.
///
/// [status] is computed from the nearest expiry across lots that still hold
/// stock, so a product whose only expired lot is empty reads "No stock" rather
/// than expired.
class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge({
    super.key,
    required this.status,
    this.expiry,
    this.today,
    this.archived = false,
  });

  final ExpiryStatus status;
  final DateTime? expiry;
  final DateTime? today;
  final bool archived;

  static final DateFormat _full = DateFormat('d MMM y');
  static final DateFormat _short = DateFormat('d MMM');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (archived) {
      return _pill(context, colors.neutral2, colors.neutral6, LocaleKeys.stock_archived.tr(), null);
    }

    if (status == ExpiryStatus.ok) {
      return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Text(
          expiry == null ? LocaleKeys.stock_notTracked.tr() : _full.format(expiry!),
          style: context.textStyles.sansCaption.copyWith(color: colors.neutral6),
        ),
      );
    }

    final (Color background, Color foreground, String label, IconData? icon) = switch (status) {
      ExpiryStatus.warning => (colors.orange0, colors.orange6, _soonLabel(), Icons.schedule_rounded),
      ExpiryStatus.critical => (colors.red0, colors.red5, _soonLabel(), Icons.schedule_rounded),
      // Expired is the only filled badge: it has already cost the shop money.
      ExpiryStatus.expired => (
          colors.red5,
          colors.isDark ? colors.neutral0 : colors.white,
          LocaleKeys.stock_expiredOn.tr(namedArgs: {'date': _short.format(expiry!)}),
          Icons.warning_amber_rounded,
        ),
      ExpiryStatus.none || ExpiryStatus.ok => (colors.neutral2, colors.neutral5, LocaleKeys.stock_noStock.tr(), null),
    };

    return _pill(context, background, foreground, label, icon);
  }

  Widget _pill(
    BuildContext context,
    Color background,
    Color foreground,
    String label,
    IconData? icon,
  ) {
    return SizedBox(
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Center(
            widthFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 12, color: foreground),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: context.textStyles.sansCaption.copyWith(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _soonLabel() {
    final from = today ?? DateTime.now();
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(expiry!.year, expiry!.month, expiry!.day);
    return '${_short.format(expiry!)} · ${end.difference(start).inDays}d';
  }
}
