import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

enum NoticeTone { info, warn, error }

/// The boxed sentence the ledger screens use to say something the figures
/// beside it cannot say on their own.
class DetailNotice extends StatelessWidget {
  const DetailNotice({super.key, required this.message, this.tone = NoticeTone.info});

  final String message;
  final NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, ink, icon) = switch (tone) {
      NoticeTone.info => (colors.primary0, colors.primary4, Icons.info_outline_rounded),
      NoticeTone.warn => (colors.orange0, colors.orange6, Icons.warning_amber_rounded),
      NoticeTone.error => (colors.red0, colors.red5, Icons.error_outline_rounded),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: context.textStyles.sansCaption.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// A label above a value, three across. The header every transaction detail
/// opens with, whatever its type.
class DetailStatRow extends StatelessWidget {
  const DetailStatRow({super.key, required this.stats});

  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.neutral0,
        border: Border(bottom: BorderSide(color: colors.neutral2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, value) in stats)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: styles.sansTableHeader.copyWith(color: colors.neutral6),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: styles.sansBodyBold.copyWith(color: colors.neutral9),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A label and a figure on one line — the shape every lot card and money panel
/// is built from.
class DetailKeyValue extends StatelessWidget {
  const DetailKeyValue({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.emphasise = false,
    this.valueColor,
  });

  final String label;
  final String value;

  /// A faint qualifier drawn beside the value, as the frames draw
  /// "3.000 *of 3.000 held*".
  final String? hint;
  final bool emphasise;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: styles.sansCaption.copyWith(color: colors.neutral6),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: (emphasise ? styles.sansBodyBold : styles.sansCaption).copyWith(
              color: valueColor ?? colors.neutral9,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(width: 5),
            Text(
              hint!,
              style: styles.sansCaption.copyWith(color: colors.neutral5),
            ),
          ],
        ],
      ),
    );
  }
}

/// The card a single lot's movement is drawn in.
class DetailLotCard extends StatelessWidget {
  const DetailLotCard({super.key, required this.title, required this.rows, this.badge});

  final String title;
  final String? badge;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.neutral0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.neutral2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.neutral2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: context.textStyles.sansCaption.copyWith(
                      color: colors.neutral7,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              Text(
                title,
                style: context.textStyles.monoBody.copyWith(color: colors.neutral6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }
}

/// The section label the ledger screens put above a group.
class DetailSectionLabel extends StatelessWidget {
  const DetailSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: context.textStyles.sansTableHeader.copyWith(
          color: context.colors.neutral6,
        ),
      ),
    );
  }
}
