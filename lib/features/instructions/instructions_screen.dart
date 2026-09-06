import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = [
    _Step(
      title: 'Find the reflection angle',
      body:
          'Hold the phone screen facing the panel and tilt it slowly until you '
          'see the screen\'s light reflected on the panel surface. '
          'You\'re looking for the same effect as a mirror.',
      painter: _AngleDiagramPainter(),
    ),
    _Step(
      title: 'Keep the right distance',
      body:
          'Hold the phone 30–60 cm from the panel. Too close — stripes are too '
          'wide and hard to track. Too far — reflection is too dim.',
      painter: _DistanceDiagramPainter(),
    ),
    _Step(
      title: 'Move slowly and steadily',
      body:
          'Slide the phone along the panel at roughly 5–10 cm per second. '
          'Fast movement blurs frames and loses the reflection angle. '
          'Imagine you\'re spreading butter on bread.',
      painter: _SpeedDiagramPainter(),
    ),
    _Step(
      title: 'Cover the full area',
      body:
          'Move in overlapping horizontal or vertical passes. '
          'Each pass should overlap the previous by about 30% '
          'so every spot is captured from multiple frames.',
      painter: _CoverageDiagramPainter(),
    ),
    _Step(
      title: 'What good stripes look like',
      body:
          'When aligned correctly you will see clear bright stripes on the panel. '
          'A dent will curve or kink the stripes. '
          'Tap "Light Test" to preview patterns before scanning.',
      painter: _StripesDiagramPainter(),
    ),
    _Step(
      title: 'Lighting conditions',
      body:
          'Indoors with dim ambient light gives the best results — '
          'direct sunlight washes out the screen reflection. '
          'A garage or shaded area is ideal.',
      painter: _LightingDiagramPainter(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Scan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _steps.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (ctx, i) => _StepPage(step: _steps[i]),
            ),
          ),
          _BottomNav(
            current: _page,
            total: _steps.length,
            onBack: _page > 0
                ? () => _controller.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
            onNext: _page < _steps.length - 1
                ? () => _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
            onDone:
                _page == _steps.length - 1 ? () => context.go('/') : null,
          ),
        ],
      ),
    );
  }
}

class _Step {
  final String title;
  final String body;
  final CustomPainter painter;

  const _Step({
    required this.title,
    required this.body,
    required this.painter,
  });
}

class _StepPage extends StatelessWidget {
  final _Step step;

  const _StepPage({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration.
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                painter: step.painter,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Text.
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  step.body,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onDone;

  const _BottomNav({
    required this.current,
    required this.total,
    this.onBack,
    this.onNext,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          // Dots.
          Row(
            children: List.generate(
              total,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == current ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i == current
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white24,
                ),
              ),
            ),
          ),
          const Spacer(),
          if (onBack != null)
            OutlinedButton(
              onPressed: onBack,
              child: const Text('Back'),
            ),
          const SizedBox(width: 12),
          if (onNext != null)
            FilledButton(
              onPressed: onNext,
              child: const Text('Next'),
            ),
          if (onDone != null)
            FilledButton(
              onPressed: onDone,
              child: const Text('Start Scanning'),
            ),
        ],
      ),
    );
  }
}

// ─── Illustrations ────────────────────────────────────────────────────────────

class _AngleDiagramPainter extends CustomPainter {
  const _AngleDiagramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Car panel — vertical rect on right.
    final panelRect =
        Rect.fromLTWH(size.width * 0.65, size.height * 0.1, 18, size.height * 0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFF3A3A4A)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(4)),
      Paint()
        ..color = Colors.white30
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Phone — tilted rectangle on left.
    final phoneCx = size.width * 0.3;
    final phoneCy = cy;
    final angle = -0.3;
    _drawPhone(canvas, phoneCx, phoneCy, 28, 56, angle);

    // Reflection arrow: phone screen → panel → back to phone camera.
    final arrowPaint = Paint()
      ..color = const Color(0xFF00C8FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final p1 = Offset(phoneCx + 18, phoneCy - 10); // screen edge
    final p2 = Offset(panelRect.left, cy - 20); // panel hit point
    final p3 = Offset(phoneCx + 14, phoneCy + 22); // camera

    canvas.drawLine(p1, p2, arrowPaint);
    canvas.drawLine(p2, p3, arrowPaint);
    _drawArrowHead(canvas, p2, p3, arrowPaint);

    // Angle arc.
    final arcPaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: p2, width: 60, height: 60),
      pi,
      -0.7,
      false,
      arcPaint,
    );

    // Labels.
    _label(canvas, 'Screen', Offset(phoneCx - 10, phoneCy - 35));
    _label(canvas, 'Reflection', Offset(cx - 20, cy - 50));
    _label(canvas, 'Camera', Offset(phoneCx - 20, phoneCy + 42));
    _label(canvas, 'Panel', Offset(panelRect.left - 10, size.height * 0.05));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _DistanceDiagramPainter extends CustomPainter {
  const _DistanceDiagramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Panel on right.
    final panelRect =
        Rect.fromLTWH(size.width * 0.72, size.height * 0.15, 16, size.height * 0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF3A3A4A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(4)),
      Paint()
        ..color = Colors.white30
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Phone on left.
    _drawPhone(canvas, size.width * 0.22, cy, 26, 52, 0);

    // Distance line with arrows.
    final y = cy + 50.0;
    final x1 = size.width * 0.22 + 13;
    final x2 = panelRect.left;
    final linePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2;

    canvas.drawLine(Offset(x1, y), Offset(x2, y), linePaint);
    _drawArrowHead(
        canvas, Offset(x2 - 10, y), Offset(x2, y), linePaint);
    _drawArrowHead(
        canvas, Offset(x1 + 10, y), Offset(x1, y), linePaint);

    // Tick marks at 30 and 60 cm.
    final range = x2 - x1;
    final tick30 = x1 + range * 0.3;
    final tick60 = x1 + range * 0.7;

    for (final x in [tick30, tick60]) {
      canvas.drawLine(Offset(x, y - 6), Offset(x, y + 6),
          Paint()..color = Colors.white30..strokeWidth = 1);
    }

    // Labels.
    _label(canvas, '30 cm', Offset(tick30 - 14, y + 12));
    _label(canvas, '60 cm', Offset(tick60 - 14, y + 12));
    _label(canvas, '30–60 cm', Offset(cx - 22, y - 20),
        color: Colors.greenAccent);
    _label(canvas, 'Too close', Offset(x1 - 8, y - 40),
        color: Colors.redAccent, size: 10);
    _label(canvas, 'Too far', Offset(x2 - 28, y - 40),
        color: Colors.redAccent, size: 10);
    _label(canvas, '✓ Ideal', Offset(cx - 18, y - 40),
        color: Colors.greenAccent, size: 10);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SpeedDiagramPainter extends CustomPainter {
  const _SpeedDiagramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Panel background.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 90, cy - 70, 180, 140),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF222230),
    );

    // Phone moving left to right with motion trail.
    final phoneY = cy - 10.0;
    _drawPhone(canvas, cx + 30, phoneY, 24, 48, 0);

    // Trail dots.
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(
        Offset(cx + 30 - i * 24.0, phoneY),
        3,
        Paint()
          ..color =
              Colors.white.withValues(alpha: 0.15 + i * 0.12),
      );
    }

    // Speed arrow.
    final arrowPaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.5;
    canvas.drawLine(
        Offset(cx - 50, phoneY - 36), Offset(cx + 50, phoneY - 36), arrowPaint);
    _drawArrowHead(canvas, Offset(cx + 40, phoneY - 36),
        Offset(cx + 50, phoneY - 36), arrowPaint);

    // Speed gauge below.
    _speedBar(canvas, size, cx, cy + 55);

    _label(canvas, '5–10 cm/sec', Offset(cx - 36, phoneY - 56),
        color: Colors.greenAccent);
  }

  void _speedBar(Canvas canvas, Size size, double cx, double y) {
    final w = 160.0;
    final h = 10.0;
    final rect = Rect.fromCenter(center: Offset(cx, y), width: w, height: h);

    // Background.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = Colors.white10,
    );

    // Gradient zones.
    final zones = [
      (0.0, 0.25, Colors.redAccent, 'Too\nslow'),
      (0.25, 0.65, Colors.greenAccent, 'Ideal'),
      (0.65, 1.0, Colors.redAccent, 'Too\nfast'),
    ];
    for (final (start, end, color, label) in zones) {
      final zRect = Rect.fromLTWH(
        rect.left + rect.width * start,
        rect.top,
        rect.width * (end - start),
        rect.height,
      );
      canvas.drawRect(
        zRect,
        Paint()..color = color.withValues(alpha: 0.5),
      );
      _label(canvas, label,
          Offset(rect.left + rect.width * (start + end) / 2 - 14, y + 14),
          size: 9, color: color);
    }

    // Needle.
    const needleX = 0.42;
    canvas.drawLine(
      Offset(rect.left + rect.width * needleX, y - 10),
      Offset(rect.left + rect.width * needleX, y + 10),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CoverageDiagramPainter extends CustomPainter {
  const _CoverageDiagramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Panel outline.
    final panelRect = Rect.fromCenter(
        center: Offset(cx, cy - 10), width: size.width * 0.65, height: size.height * 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF222230),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(8)),
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Scanning passes — horizontal arrows with overlap.
    final passCount = 4;
    final passSpacing = panelRect.height / (passCount + 1);
    final colors = [
      Colors.cyanAccent,
      Colors.cyanAccent.withValues(alpha: 0.7),
      Colors.cyanAccent.withValues(alpha: 0.5),
      Colors.cyanAccent.withValues(alpha: 0.3),
    ];

    for (var i = 0; i < passCount; i++) {
      final y = panelRect.top + passSpacing * (i + 1);
      final goRight = i % 2 == 0;
      final x1 = goRight ? panelRect.left + 10 : panelRect.right - 10;
      final x2 = goRight ? panelRect.right - 10 : panelRect.left + 10;

      final paint = Paint()
        ..color = colors[i]
        ..strokeWidth = 2;

      canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
      _drawArrowHead(canvas, Offset(x2 - (goRight ? 10 : -10), y),
          Offset(x2, y), paint);

      // Overlap band.
      if (i < passCount - 1) {
        canvas.drawRect(
          Rect.fromLTWH(panelRect.left + 10, y,
              panelRect.width - 20, passSpacing * 0.3),
          Paint()
            ..color = colors[i].withValues(alpha: 0.08),
        );
      }
    }

    _label(canvas, '30% overlap', Offset(cx - 28, panelRect.bottom + 10),
        color: Colors.white54, size: 11);
    _label(canvas, 'Scanning passes', Offset(cx - 40, panelRect.top - 22),
        color: Colors.white70);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StripesDiagramPainter extends CustomPainter {
  const _StripesDiagramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.38;
    final h = size.height * 0.6;

    // Left panel — good stripes (straight).
    final leftRect = Rect.fromCenter(
        center: Offset(cx - size.width * 0.25, cy), width: w, height: h);
    _drawPanelWithStripes(canvas, leftRect, hasDent: false);
    _label(canvas, '✓ Good', Offset(leftRect.center.dx - 20, leftRect.bottom + 10),
        color: Colors.greenAccent);

    // Right panel — dented stripes (kinked).
    final rightRect = Rect.fromCenter(
        center: Offset(cx + size.width * 0.25, cy), width: w, height: h);
    _drawPanelWithStripes(canvas, rightRect, hasDent: true);
    _label(canvas, '⚠ Dent', Offset(rightRect.center.dx - 20, rightRect.bottom + 10),
        color: Colors.orangeAccent);
  }

  void _drawPanelWithStripes(Canvas canvas, Rect rect,
      {required bool hasDent}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF1A1A2A),
    );
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)));

    final stripePaint = Paint()
      ..color = const Color(0xFF00C8FF).withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const stripeCount = 6;
    final step = rect.width / stripeCount;

    for (var i = 0; i <= stripeCount; i++) {
      final x = rect.left + step * i;
      if (!hasDent) {
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), stripePaint);
      } else {
        // Draw stripe with kink in the middle.
        final path = Path();
        final dentCx = rect.left + rect.width * 0.55;
        final dentCy = rect.top + rect.height * 0.45;
        final dentRadius = rect.width * 0.18;
        final dx = (x - dentCx) / dentRadius;
        final kink = dx.abs() < 1 ? 10.0 * (1 - dx * dx) : 0.0;

        path.moveTo(x, rect.top);
        for (var y = rect.top; y <= rect.bottom; y += 2) {
          final dy = (y - dentCy) / dentRadius;
          final localKink = (dx.abs() < 1 && dy.abs() < 1)
              ? kink * (1 - dy * dy).clamp(0.0, 1.0)
              : 0.0;
          path.lineTo(x + localKink, y);
        }
        canvas.drawPath(path, stripePaint);
      }
    }

    if (hasDent) {
      // Dent circle indicator.
      canvas.drawCircle(
        Offset(rect.left + rect.width * 0.55, rect.top + rect.height * 0.45),
        rect.width * 0.18,
        Paint()
          ..color = Colors.orangeAccent.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(rect.left + rect.width * 0.55, rect.top + rect.height * 0.45),
        rect.width * 0.18,
        Paint()
          ..color = Colors.orangeAccent.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    canvas.restore();

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _LightingDiagramPainter extends CustomPainter {
  const _LightingDiagramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Left: bad — sun icon + red cross.
    final sunCenter = Offset(cx * 0.45, cy - 20);
    _drawSun(canvas, sunCenter, 32, Colors.yellow);
    _label(canvas, '✗ Direct sunlight',
        Offset(sunCenter.dx - 46, sunCenter.dy + 46),
        color: Colors.redAccent, size: 11);

    // X mark.
    final xPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3;
    canvas.drawLine(
        sunCenter + const Offset(-12, -12), sunCenter + const Offset(12, 12), xPaint);
    canvas.drawLine(
        sunCenter + const Offset(12, -12), sunCenter + const Offset(-12, 12), xPaint);

    // Divider.
    canvas.drawLine(Offset(cx, size.height * 0.15), Offset(cx, size.height * 0.8),
        Paint()..color = Colors.white12..strokeWidth = 1);

    // Right: good — garage icon.
    final garageCenter = Offset(cx + cx * 0.55, cy - 20);
    _drawGarage(canvas, garageCenter, 36);
    _label(canvas, '✓ Dim indoor',
        Offset(garageCenter.dx - 34, garageCenter.dy + 46),
        color: Colors.greenAccent, size: 11);

    _label(canvas, 'Lighting', Offset(cx - 24, size.height * 0.08),
        color: Colors.white70);
  }

  void _drawSun(Canvas canvas, Offset center, double r, Color color) {
    canvas.drawCircle(center, r * 0.55, Paint()..color = color.withValues(alpha: 0.8));
    final rayPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    for (var i = 0; i < 8; i++) {
      final angle = pi / 4 * i;
      canvas.drawLine(
        center + Offset(cos(angle) * r * 0.65, sin(angle) * r * 0.65),
        center + Offset(cos(angle) * r, sin(angle) * r),
        rayPaint,
      );
    }
  }

  void _drawGarage(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Walls.
    canvas.drawRect(
        Rect.fromCenter(center: center, width: size * 1.4, height: size * 1.2),
        paint);

    // Roof triangle.
    final path = Path()
      ..moveTo(center.dx - size * 0.9, center.dy - size * 0.6)
      ..lineTo(center.dx, center.dy - size * 1.15)
      ..lineTo(center.dx + size * 0.9, center.dy - size * 0.6);
    canvas.drawPath(path, paint);

    // Door stripes.
    final doorPaint = Paint()
      ..color = Colors.white20
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      canvas.drawLine(
        Offset(center.dx - size * 0.6, center.dy - size * 0.6 + i * size * 0.3),
        Offset(center.dx + size * 0.6, center.dy - size * 0.6 + i * size * 0.3),
        doorPaint,
      );
    }

    // Dim light bulb.
    canvas.drawCircle(
        Offset(center.dx, center.dy - size * 0.1), 5,
        Paint()..color = Colors.yellowAccent.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

void _drawPhone(Canvas canvas, double cx, double cy, double w, double h,
    double angle) {
  canvas.save();
  canvas.translate(cx, cy);
  canvas.rotate(angle);

  // Body.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      const Radius.circular(5),
    ),
    Paint()..color = const Color(0xFF2A2A3A),
  );

  // Screen (glowing).
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w - 4, height: h - 10),
      const Radius.circular(3),
    ),
    Paint()..color = const Color(0xFF00C8FF).withValues(alpha: 0.3),
  );

  // Screen lines.
  final linePaint = Paint()
    ..color = const Color(0xFF00C8FF).withValues(alpha: 0.7)
    ..strokeWidth = 1;
  const lineCount = 4;
  final step = (w - 4) / (lineCount + 1);
  for (var i = 1; i <= lineCount; i++) {
    final x = -(w - 4) / 2 + step * i;
    canvas.drawLine(Offset(x, -h / 2 + 6), Offset(x, h / 2 - 6), linePaint);
  }

  // Camera dot (front-facing, at bottom when rotated).
  canvas.drawCircle(
    Offset(0, h / 2 - 4),
    3,
    Paint()..color = Colors.white30,
  );

  canvas.restore();
}

void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
  const headLen = 8.0;
  const headAngle = 0.4;
  final angle = atan2(to.dy - from.dy, to.dx - from.dx);

  final p1 = Offset(
    to.dx - headLen * cos(angle - headAngle),
    to.dy - headLen * sin(angle - headAngle),
  );
  final p2 = Offset(
    to.dx - headLen * cos(angle + headAngle),
    to.dy - headLen * sin(angle + headAngle),
  );

  canvas.drawLine(to, p1, paint);
  canvas.drawLine(to, p2, paint);
}

void _label(
  Canvas canvas,
  String text,
  Offset pos, {
  Color color = Colors.white70,
  double size = 11,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: size, height: 1.3),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, pos);
}
