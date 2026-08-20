import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

enum AuthBannerTone { error, success }

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    super.key,
    required this.message,
    this.tone = AuthBannerTone.error,
  });

  final String message;
  final AuthBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (background, foreground) = switch (tone) {
      AuthBannerTone.error => (colors.red0, colors.red5),
      AuthBannerTone.success => (colors.green0, colors.green5),
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        message,
        style: context.textStyles.sansBody.copyWith(color: foreground),
      ),
    );
  }
}
