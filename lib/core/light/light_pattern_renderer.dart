import 'package:flutter/material.dart';

import 'light_pattern.dart';

class LightPatternRenderer extends CustomPainter {
  final LightPattern pattern;

  // Driven by AnimationController — kept separate to avoid 60fps Riverpod churn.
  final double animatedPhase;

  const LightPatternRenderer({
    required this.pattern,
    required this.animatedPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _fillBackground(canvas, size);

    switch (pattern.type) {
      case LightPatternType.verticalStripes:
      case LightPatternType.fineVertical:
      case LightPatternType.wideVertical:
      case LightPatternType.movingVertical:
      case LightPatternType.phaseShiftedVertical:
        _drawStripes(canvas, size, Axis.vertical);
      case LightPatternType.horizontalStripes:
      case LightPatternType.movingHorizontal:
        _drawStripes(canvas, size, Axis.horizontal);
      case LightPatternType.checkerboard:
        _drawCheckerboard(canvas, size);
    }
  }

  void _fillBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromARGB(
        (pattern.brightness * 255).round().clamp(0, 255),
        pattern.backgroundColor.r.round(),
        pattern.backgroundColor.g.round(),
        pattern.backgroundColor.b.round(),
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawStripes(Canvas canvas, Size size, Axis axis) {
    final paint = Paint()
      ..color = Color.fromARGB(
        (pattern.brightness * 255).round().clamp(0, 255),
        pattern.foregroundColor.r.round(),
        pattern.foregroundColor.g.round(),
        pattern.foregroundColor.b.round(),
      );

    final period = pattern.stripeWidth + pattern.stripeSpacing;
    if (period <= 0) return;

    final offset = animatedPhase % period;

    if (axis == Axis.vertical) {
      var x = -period + offset;
      while (x < size.width) {
        canvas.drawRect(
          Rect.fromLTWH(x, 0, pattern.stripeWidth.toDouble(), size.height),
          paint,
        );
        x += period;
      }
    } else {
      var y = -period + offset;
      while (y < size.height) {
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, pattern.stripeWidth.toDouble()),
          paint,
        );
        y += period;
      }
    }
  }

  void _drawCheckerboard(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromARGB(
        (pattern.brightness * 255).round().clamp(0, 255),
        pattern.foregroundColor.r.round(),
        pattern.foregroundColor.g.round(),
        pattern.foregroundColor.b.round(),
      );

    final cellSize = pattern.stripeWidth.toDouble();
    if (cellSize <= 0) return;

    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if ((row + col) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              col * cellSize,
              row * cellSize,
              cellSize,
              cellSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(LightPatternRenderer old) =>
      old.pattern != pattern || old.animatedPhase != animatedPhase;
}
