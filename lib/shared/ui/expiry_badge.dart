import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mine_storage/app/theme/theme.dart';
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
      return _pill(context, colors.neutral2, colors.neutral6, 'Archived');
    }

    if (status == ExpiryStatus.healthy) {
      return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Text(
          expiry == null ? 'Not tracked' : _full.format(expiry!),
          style: context.textStyles.sansCaption.copyWith(color: colors.neutral6),
        ),
      );
    }

    final (Color background, Color foreground, String label) = switch (status) {
      ExpiryStatus.expiringSoon => (colors.orange0, colors.orange6, _soonLabel()),
      ExpiryStatus.expired => (colors.red0, colors.red5, '${_short.format(expiry!)} · expired'),
      ExpiryStatus.none || ExpiryStatus.healthy => (colors.neutral2, colors.neutral5, 'No stock'),
    };

    return _pill(context, background, foreground, label);
  }

  Widget _pill(BuildContext context, Color background, Color foreground, String label) {
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
            child: Text(
              label,
              style: context.textStyles.sansCaption.copyWith(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.11,
              ),
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
