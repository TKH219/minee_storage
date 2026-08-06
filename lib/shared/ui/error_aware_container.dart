import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

/// Standard full-screen error surface with a retry affordance.
class ErrorAwareContainer extends StatelessWidget {
  const ErrorAwareContainer({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: context.colors.red5),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: context.textStyles.sansBodyBold,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textStyles.sansBody.copyWith(color: context.colors.neutral6),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(minimumSize: const Size(160, 44)),
                child: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
