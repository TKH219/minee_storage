import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.red0,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        message,
        style: context.textStyles.sansBody.copyWith(color: colors.red5),
      ),
    );
  }
}
