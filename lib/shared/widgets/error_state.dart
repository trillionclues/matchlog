// Displays icon, message, and a retry button.

library;

import 'package:flutter/material.dart';
import '../../core/theme/spacing.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MatchLogSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            MatchLogSpacing.gapLg,
            Text(
              'Something went wrong',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            MatchLogSpacing.gapSm,
            Text(
              message,
              style: theme.textTheme.bodyMedium,
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
