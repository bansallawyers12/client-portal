import 'package:flutter/material.dart';

/// Wraps a child so it scales down slightly while pressed and springs
/// back on release — gives every tappable card a tactile, modern feel.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  final BorderRadius? borderRadius;

  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.95,
    this.borderRadius,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
