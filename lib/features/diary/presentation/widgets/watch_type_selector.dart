library;

import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import 'interactive_chip.dart';

class WatchTypeSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;

  const WatchTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _types = [
    ('stadium', Icons.stadium_outlined, 'Stadium'),
    ('tv', Icons.tv_outlined, 'TV'),
    ('streaming', Icons.wifi_outlined, 'Streaming'),
    ('radio', Icons.radio_outlined, 'Radio'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: MatchLogSpacing.sm,
      runSpacing: MatchLogSpacing.sm,
      children: _types.map((type) {
        final isSelected = selected == type.$1;
        return InteractiveChip(
          selected: isSelected,
          child: ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    type.$2,
                    key: ValueKey('${type.$1}-$isSelected'),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Text(type.$3),
              ],
            ),
            selected: isSelected,
            onSelected: (_) => onChanged(type.$1),
          ),
        );
      }).toList(),
    );
  }
}
