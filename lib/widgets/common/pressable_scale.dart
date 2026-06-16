import 'package:flutter/material.dart';

/// Wraps a child so it zooms out while pressed and springs back with a
/// subtle zoom-in overshoot on release — a tactile "pop" on every tap.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  final BorderRadius? borderRadius;

  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.93,
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
        // Quick easeOut zoom-out on press; slower easeOutBack on release
        // gives a springy zoom-in overshoot before settling.
        duration: Duration(milliseconds: _pressed ? 120 : 280),
        curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
