import 'package:flutter/material.dart';

/// Adds a subtle press-scale micro-interaction without hijacking gestures.
///
/// Uses [Listener] so child widgets (InkWell, IconButton, etc.) keep their
/// own tap handling and ripple effects.
class PressScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final Duration duration;
  final Curve curve;

  const PressScale({
    super.key,
    required this.child,
    this.pressedScale = 0.98,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.easeOut,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}
