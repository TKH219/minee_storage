import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/gen/assets.gen.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.controller,
    this.enabled = true,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextEditingController? controller;
  final bool enabled;
  final bool obscureText;

  /// Supplying this is what puts the reveal control on the field.
  final VoidCallback? onToggleObscure;

  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textStyles.sansTableHeader.copyWith(
            color: colors.neutral7,
            letterSpacing: 0.12,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: _obscureToggle(context),
            suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
        if (errorText == null && helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: context.textStyles.sansCaption.copyWith(color: colors.neutral6),
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: context.textStyles.sansCaption.copyWith(color: colors.red5),
          ),
        ],
      ],
    );
  }

  Widget? _obscureToggle(BuildContext context) {
    final onToggle = onToggleObscure;
    if (onToggle == null) return null;

    // The two assets are named for the state they belong to, not the action
    // they perform: `icPasswordHide` is the plain eye shown while the password
    // is hidden, `icPasswordShow` the struck-through one shown while it is not.
    final icon = obscureText ? Assets.icons.icPasswordHide : Assets.icons.icPasswordShow;

    return IconButton(
      onPressed: onToggle,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      tooltip: (obscureText ? LocaleKeys.common_showPassword : LocaleKeys.common_hidePassword).tr(),
      icon: icon.tinted(context.colors.neutral6, width: 20, height: 20),
    );
  }
}
