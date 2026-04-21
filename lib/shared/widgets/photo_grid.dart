// Displays grid of match photos from Firebase Storage URLs.
// Used in match diary entry cards and detail screens.

library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

class PhotoGrid extends StatelessWidget {
  final List<String> photoUrls;
  final int maxVisible;
  final double itemSize;
  final VoidCallback? onTapMore;

  const PhotoGrid({
    super.key,
    required this.photoUrls,
    this.maxVisible = 3,
    this.itemSize = 72,
    this.onTapMore,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) return const SizedBox.shrink();

    final visiblePhotos = photoUrls.take(maxVisible).toList();
    final remaining = photoUrls.length - maxVisible;

    return Row(
      children: [
        ...visiblePhotos.asMap().entries.map((entry) {
          final isLast = entry.key == visiblePhotos.length - 1;
          return Padding(
            padding: EdgeInsets.only(
              right: isLast ? 0 : MatchLogSpacing.sm,
            ),
            child: _PhotoThumbnail(
              url: entry.value,
              size: itemSize,
            ),
          );
        }),
        if (remaining > 0) ...[
          const SizedBox(width: MatchLogSpacing.sm),
          GestureDetector(
            onTap: onTapMore,
            child: Container(
              width: itemSize,
              height: itemSize,
              decoration: BoxDecoration(
                color: MatchLogColors.surfaceElevated,
                borderRadius: MatchLogSpacing.roundedSm,
              ),
              child: Center(
                child: Text(
                  '+$remaining',
                  style: const TextStyle(
                    color: MatchLogColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final String url;
  final double size;

  const _PhotoThumbnail({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: MatchLogSpacing.roundedSm,
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          color: MatchLogColors.surfaceElevated,
        ),
        errorWidget: (_, __, ___) => Container(
          width: size,
          height: size,
          color: MatchLogColors.surfaceElevated,
          child: const Icon(
            Icons.broken_image_outlined,
            color: MatchLogColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
