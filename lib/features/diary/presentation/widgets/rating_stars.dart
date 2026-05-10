
library;

import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double size;
  final ValueChanged<int>? onChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 24,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (i) {
        final filled = i < rating;
        return GestureDetector(
          onTap: onChanged != null ? () => onChanged!(i + 1) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: filled
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.25),
            ),
          ),
        );
      }),
    );
  }
}
