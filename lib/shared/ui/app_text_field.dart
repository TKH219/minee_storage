import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final bool enabled;
  final bool obscureText;
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
          decoration: InputDecoration(hintText: hint),
        ),
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
}
