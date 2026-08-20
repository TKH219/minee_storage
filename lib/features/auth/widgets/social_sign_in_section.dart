import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/gen/assets.gen.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

/// Whether to offer the Apple button — iOS only.
///
/// Deliberately [Platform.isIOS] and not `defaultTargetPlatform`: the latter is
/// annotated `vm:platform-const-if`, so release AOT builds fold it to a
/// constant and tree-shake the losing branch, which silently drops the button
/// from device builds while it still renders in debug.
bool get _isIOS => debugIsIOSOverride ?? Platform.isIOS;

/// Test-only override for [_isIOS]; `debugDefaultTargetPlatformOverride` cannot
/// stand in, since it is itself gated on `kDebugMode`.
@visibleForTesting
bool? debugIsIOSOverride;

/// The "or continue with" divider plus the Apple/Google buttons.
///
/// Layout is a 12pt stack of an 18pt divider row and a 44pt button row; the
/// divider is inset 48pt each side with 6pt gaps around the label, and the two
/// buttons split the row with a 12pt gap.
class SocialSignInSection extends StatelessWidget {
  const SocialSignInSection({super.key, this.onApple, this.onGoogle});

  final VoidCallback? onApple;
  final VoidCallback? onGoogle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDivider(context),
        const SizedBox(height: 12),
        _buildButtons(context),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final line = Divider(color: context.colors.neutral3, thickness: 0.5, height: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [
          Expanded(child: line),
          const SizedBox(width: 6),
          Text(
            LocaleKeys.auth_social_continueWith.tr(),
            style: context.textStyles.sansCaption.copyWith(color: context.colors.neutral6),
          ),
          const SizedBox(width: 6),
          Expanded(child: line),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        if (_isIOS) ...[
          Expanded(
            child: _SocialButton(
              label: LocaleKeys.auth_social_apple.tr(),
              // The glyph and the label share one colour.
              icon: Assets.icons.icApple.tinted(context.colors.neutral9, width: 24, height: 24),
              onPressed: onApple,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _SocialButton(
            label: LocaleKeys.auth_social_google.tr(),
            // The Google "G" keeps its four brand colours — never tinted.
            icon: Assets.icons.icGoogle.svg(width: 24, height: 24),
            onPressed: onGoogle,
          ),
        ),
      ],
    );
  }
}

/// 44pt tall, surface-filled, hairline border, radius 8, 16pt horizontal
/// padding, 12pt icon-to-label gap.
class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon, this.onPressed});

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.neutral0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: BorderSide(color: colors.neutral3, width: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 12),
            // The button is half the content width; on the narrowest phones the
            // label shrinks rather than overflowing.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.sansBodyBold.copyWith(color: colors.neutral9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
