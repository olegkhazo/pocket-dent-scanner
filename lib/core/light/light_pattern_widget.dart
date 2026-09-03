import 'package:flutter/material.dart';

import 'light_pattern.dart';
import 'light_pattern_renderer.dart';

// Animates moving patterns via AnimationController.
// Static patterns render instantly; moving patterns drive phase at 60fps
// without touching Riverpod state (avoids 60fps provider churn).
class LightPatternWidget extends StatefulWidget {
  final LightPattern pattern;

  const LightPatternWidget({super.key, required this.pattern});

  @override
  State<LightPatternWidget> createState() => LightPatternWidgetState();
}

class LightPatternWidgetState extends State<LightPatternWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Loop duration in seconds — phase rolls over at this interval.
  static const double _loopSeconds = 10.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _loopSeconds ~/ 1),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(LightPatternWidget old) {
    super.didUpdateWidget(old);
    if (old.pattern.type != widget.pattern.type ||
        old.pattern.movementSpeed != widget.pattern.movementSpeed) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (_isAnimated(widget.pattern.type)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  bool _isAnimated(LightPatternType type) =>
      type == LightPatternType.movingVertical ||
      type == LightPatternType.movingHorizontal;

  // Phase in pixels at the current animation tick.
  // period is stripeWidth + stripeSpacing; we drive phase through one full period.
  double _computePhase() {
    if (!_isAnimated(widget.pattern.type)) return widget.pattern.phase;
    final period =
        (widget.pattern.stripeWidth + widget.pattern.stripeSpacing).toDouble();
    return (_controller.value * widget.pattern.movementSpeed * period) % period;
  }

  // Exposes exact phase at a given wall-clock timestamp for CV frame sync.
  double currentPhase() => _computePhase();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: LightPatternRenderer(
          pattern: widget.pattern,
          animatedPhase: _computePhase(),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
