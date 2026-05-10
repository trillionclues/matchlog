library;

import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';

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
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.$2, size: 16),
              const SizedBox(width: 6),
              Text(type.$3),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(type.$1),
        );
      }).toList(),
    );
  }
}
