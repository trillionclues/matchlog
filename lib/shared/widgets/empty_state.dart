// Centered icon + title + subtitle + optional CTA button.

library;

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaText;
  final VoidCallback? onCta;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaText,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MatchLogSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: MatchLogColors.textTertiary,
            ),
            MatchLogSpacing.gapLg,
            Text(
              title,
              style: MatchLogTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            MatchLogSpacing.gapSm,
            Text(
              subtitle,
              style: MatchLogTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (ctaText != null && onCta != null) ...[
              MatchLogSpacing.gapXl,
              ElevatedButton(
                onPressed: onCta,
                child: Text(ctaText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
