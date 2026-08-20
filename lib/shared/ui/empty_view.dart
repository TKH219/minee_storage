import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.onAction,
    this.actionLabel,
  });

  final String? title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: context.colors.neutral4),
            const SizedBox(height: 16),
            Text(
              title ?? LocaleKeys.common_nothingHereYet.tr(),
              textAlign: TextAlign.center,
              style: context.textStyles.sansBodyBold,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: context.textStyles.sansBody.copyWith(color: context.colors.neutral6),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
