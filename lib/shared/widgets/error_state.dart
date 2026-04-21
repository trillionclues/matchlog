// Displays icon, message, and a retry button.

library;

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Try again',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MatchLogSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: MatchLogColors.error,
            ),
            MatchLogSpacing.gapLg,
            Text(
              'Something went wrong',
              style: MatchLogTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            MatchLogSpacing.gapSm,
            Text(
              message,
              style: MatchLogTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            MatchLogSpacing.gapXl,
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
