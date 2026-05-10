library;

import 'package:flutter/material.dart';

class InteractiveChip extends StatefulWidget {
  final bool selected;
  final Widget child;

  const InteractiveChip({
    super.key,
    required this.selected,
    required this.child,
  });

  @override
  State<InteractiveChip> createState() => _InteractiveChipState();
}

class _InteractiveChipState extends State<InteractiveChip> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.94 : 1.0;

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        scale: scale,
        child: widget.child,
      ),
    );
  }
}
