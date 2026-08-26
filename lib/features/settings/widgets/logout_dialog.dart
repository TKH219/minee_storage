import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

/// Confirms the one action here that cannot be undone from this screen.
///
/// It names the account on purpose: on a shared device the wrong sign-out is
/// an easy mistake, and the email is what tells them apart.
class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key, required this.email});

  final String email;

  /// From the design's `.p-dialog` and Figma node `3321:15963`. The spec's
  /// task list says 10, but both the design HTML and the Figma node say 16 —
  /// 10 is the snack bar's radius.
  static const double radius = 16;

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(20, 22, 20, 16);
  static const double titleSize = 18;
  static const double bodySize = 14;
  static const double actionGap = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.textStyles;

    return AlertDialog(
      backgroundColor: colors.neutral0,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      titlePadding: contentPadding,
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      title: Text(
        LocaleKeys.settings_logOutTitle.tr(),
        style: texts.sansBodyBold.copyWith(fontSize: titleSize),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.settings_logOutBody.tr(),
            style: texts.sansBody.copyWith(
              fontSize: bodySize,
              height: 1.5,
              color: colors.neutral7,
            ),
          ),
          if (email.trim().isNotEmpty) ...[
            const SizedBox(height: actionGap),
            Text(
              LocaleKeys.settings_logOutAccount.tr(namedArgs: {'email': email}),
              style: texts.sansCaption.copyWith(color: colors.neutral6),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const Key('logout-stay'),
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: colors.primary4,
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(LocaleKeys.settings_stay.tr()),
        ),
        FilledButton(
          key: const Key('logout-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colors.red5,
            foregroundColor: colors.white,
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(LocaleKeys.settings_logOut.tr()),
        ),
      ],
    );
  }
}

Future<bool> showLogoutDialog(BuildContext context, {required String email}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => LogoutDialog(email: email),
  );
  return confirmed ?? false;
}
