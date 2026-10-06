import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Circular progress that animates smoothly whenever [progress] changes and
/// fills up from empty the first time it appears.
class ProgressRing extends StatelessWidget {
  /// 0.0 – 1.0. Values above 1 draw a full ring.
  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color? trackColor;
  final Duration duration;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 120,
    this.strokeWidth = 10,
    this.trackColor,
    this.duration = AppMotion.slow,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final track = trackColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    final target = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: reduceMotion ? Duration.zero : duration,
      curve: AppMotion.enter,
      builder: (context, value, inner) => CustomPaint(
        painter: _RingPainter(
          progress: value,
          color: color,
          trackColor: track,
          strokeWidth: strokeWidth,
        ),
        child: inner,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
