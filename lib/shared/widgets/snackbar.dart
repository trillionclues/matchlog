library;

import 'package:flutter/material.dart';
import '../../core/theme/spacing.dart';

enum SnackBarVariant { success, error, info }

class MatchLogSnackBar {
  MatchLogSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    SnackBarVariant variant = SnackBarVariant.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final (Color bg, Color fg, IconData icon) = switch (variant) {
      SnackBarVariant.success => (
          colorScheme.primary,
          colorScheme.onPrimary,
          Icons.check_circle_rounded,
        ),
      SnackBarVariant.error => (
          colorScheme.error,
          colorScheme.onError,
          Icons.error_rounded,
        ),
      SnackBarVariant.info => (
          colorScheme.onSurface,
          colorScheme.surface,
          Icons.info_rounded,
        ),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: MatchLogSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                ),
              ),
            ],
          ),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: MatchLogSpacing.roundedMd,
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: MatchLogSpacing.lg,
            vertical: MatchLogSpacing.sm,
          ),
          duration: duration,
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: fg,
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, variant: SnackBarVariant.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, variant: SnackBarVariant.error);

  static void info(BuildContext context, String message) =>
      show(context, message: message, variant: SnackBarVariant.info);
}
