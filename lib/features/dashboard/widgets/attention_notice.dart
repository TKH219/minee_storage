import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';

import 'dashboard_metrics.dart';

/// One row of the Needs-attention block.
///
/// Always tappable: an alert the user cannot act on is a dead notice, and the
/// design is explicit that every one of these leads into the screen that fixes
/// it.
class AttentionNotice extends StatelessWidget {
  const AttentionNotice({
    super.key,
    required this.kind,
    required this.headline,
    required this.body,
    required this.onTap,
  });

  final AttentionAlertKind kind;
  final String headline;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, ink, icon) = switch (kind) {
      AttentionAlertKind.expired => (
        colors.red0,
        colors.red5,
        Icons.warning_amber_rounded,
      ),
      AttentionAlertKind.expiringSoon => (
        colors.orange0,
        colors.orange6,
        Icons.schedule_rounded,
      ),
      AttentionAlertKind.outOfStock => (
        colors.primary0,
        colors.primary5,
        Icons.info_outline_rounded,
      ),
    };

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(DashboardMetrics.noticeRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: DashboardMetrics.noticePadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: DashboardMetrics.noticeIconSize, color: ink),
              const SizedBox(width: DashboardMetrics.noticeGap),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: headline,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' $body'),
                    ],
                  ),
                  style: context.textStyles.sansBody.copyWith(
                    fontSize: DashboardMetrics.noticeTextSize,
                    height: DashboardMetrics.noticeTextHeight,
                    color: ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
