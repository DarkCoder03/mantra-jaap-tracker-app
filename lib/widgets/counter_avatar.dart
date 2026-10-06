import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/mantra_icon.dart';
import '../providers/counter_provider.dart';

/// A counter's symbol inside a softly tinted circle.
class CounterAvatar extends StatelessWidget {
  final MantraIcon icon;
  final Color color;
  final double size;

  /// Text shown instead of the sparkle when [icon] is "Custom".
  final String? customGlyph;

  const CounterAvatar({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.customGlyph,
  });

  factory CounterAvatar.of(CounterProfile counter, {Key? key, double size = 40}) => CounterAvatar(
        key: key,
        icon: counter.icon,
        color: counter.color,
        size: size,
        customGlyph: counter.customGlyph,
      );

  /// Shared Hero tag so the avatar flies between Home and the counter screen.
  static String heroTag(String counterId) => 'counter-avatar-$counterId';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final custom = icon.isCustom ? (customGlyph?.trim() ?? '') : '';

    final Widget content = custom.isNotEmpty
        ? _CustomGlyph(text: custom, color: color, size: size)
        : MantraSymbolView(symbol: icon.symbol, color: color, size: size * 0.6);

    // Material keeps text styling intact while the avatar is in Hero flight.
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: isDark ? 0.20 : 0.14),
        ),
        child: content,
      ),
    );
  }
}

/// One symbol from the app's icon set, at any size.
class MantraSymbolView extends StatelessWidget {
  final MantraSymbol symbol;
  final Color color;
  final double size;

  const MantraSymbolView({super.key, required this.symbol, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: MantraSymbolPainter(symbol: symbol, color: color),
      ),
    );
  }
}

class _CustomGlyph extends StatelessWidget {
  final String text;
  final Color color;
  final double size;

  const _CustomGlyph({required this.text, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    // Shrinks longer text so it always fits inside the circle.
    return Padding(
      padding: EdgeInsets.all(size * 0.18),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontSize: size * 0.46,
            height: 1.15,
            fontWeight: FontWeight.w600,
            color: color,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

/// Draws the symbol set: one 24×24 grid, one 1.6-unit stroke weight, round
/// caps and joins, and at most one small filled accent per symbol, so every
/// symbol looks like part of the same family at any size.
class MantraSymbolPainter extends CustomPainter {
  final MantraSymbol symbol;
  final Color color;

  const MantraSymbolPainter({required this.symbol, required this.color});

  static const double _grid = 24;
  static const double _strokeWidth = 1.6;

  /// Paths are built once and reused for every avatar.
  static final Map<MantraSymbol, _SymbolPaths> _cache = {
    for (final s in MantraSymbol.values) s: _build(s),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paths = _cache[symbol]!;
    final scale = math.min(size.width, size.height) / _grid;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    if (paths.rotationDegrees != 0) canvas.rotate(paths.rotationDegrees * math.pi / 180);
    canvas.translate(-_grid / 2, -_grid / 2);

    canvas.drawPath(
      paths.stroke,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    final fill = paths.fill;
    if (fill != null) {
      canvas.drawPath(fill, Paint()..color = color..isAntiAlias = true);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MantraSymbolPainter old) => old.symbol != symbol || old.color != color;

  static _SymbolPaths _build(MantraSymbol symbol) => switch (symbol) {
    MantraSymbol.lotus => _SymbolPaths(
      rotationDegrees: 0,
      stroke: Path()
        ..moveTo(12, 4.5)
        ..cubicTo(14.8, 7.5, 14.8, 13, 12, 16.5)
        ..cubicTo(9.2, 13, 9.2, 7.5, 12, 4.5)
        ..close()
        ..moveTo(12, 16.5)
        ..cubicTo(8.6, 16.2, 6.1, 13.4, 5.6, 9.4)
        ..cubicTo(8.7, 10.1, 11, 12.7, 12, 16.5)
        ..moveTo(12, 16.5)
        ..cubicTo(15.4, 16.2, 17.9, 13.4, 18.4, 9.4)
        ..cubicTo(15.3, 10.1, 13, 12.7, 12, 16.5)
        ..moveTo(12, 16.5)
        ..cubicTo(8.8, 18.2, 5.2, 17.6, 2.8, 15)
        ..cubicTo(6, 14.1, 9.4, 14.8, 12, 16.5)
        ..moveTo(12, 16.5)
        ..cubicTo(15.2, 18.2, 18.8, 17.6, 21.2, 15)
        ..cubicTo(18, 14.1, 14.6, 14.8, 12, 16.5)
        ..moveTo(8.5, 20)
        ..lineTo(15.5, 20),
      fill: null,
    ),
    MantraSymbol.bow => _SymbolPaths(
      rotationDegrees: -45,
      stroke: Path()
        ..moveTo(8.5, 3)
        ..cubicTo(14.5, 6.5, 14.5, 17.5, 8.5, 21)
        ..moveTo(8.5, 3)
        ..lineTo(8.5, 21)
        ..moveTo(3.5, 12)
        ..lineTo(21, 12)
        ..moveTo(17.6, 9)
        ..lineTo(21, 12)
        ..lineTo(17.6, 15)
        ..moveTo(6.6, 12)
        ..lineTo(4.8, 10.2)
        ..moveTo(6.6, 12)
        ..lineTo(4.8, 13.8),
      fill: null,
    ),
    MantraSymbol.tripundra => _SymbolPaths(
      rotationDegrees: 0,
      stroke: Path()
        ..moveTo(4, 8)
        ..quadraticBezierTo(12, 6.2, 20, 8)
        ..moveTo(4, 12)
        ..quadraticBezierTo(6.8, 11.1, 9.4, 10.9)
        ..moveTo(14.6, 10.9)
        ..quadraticBezierTo(17.2, 11.1, 20, 12)
        ..moveTo(4, 16)
        ..quadraticBezierTo(12, 14.2, 20, 16),
      fill: Path()
        ..moveTo(12, 9)
        ..cubicTo(13.3, 9, 13.9, 10, 13.9, 10.9)
        ..cubicTo(13.9, 12.1, 12.9, 13, 12, 13)
        ..cubicTo(11.1, 13, 10.1, 12.1, 10.1, 10.9)
        ..cubicTo(10.1, 10, 10.7, 9, 12, 9)
        ..close(),
    ),
    MantraSymbol.morPankh => _SymbolPaths(
      rotationDegrees: -24,
      stroke: Path()
        ..moveTo(12, 1.5)
        ..cubicTo(16, 2.8, 17.4, 7, 16.2, 10.6)
        ..cubicTo(15.3, 13.3, 13.4, 15.4, 12, 17)
        ..cubicTo(10.6, 15.4, 8.7, 13.3, 7.8, 10.6)
        ..cubicTo(6.6, 7, 8, 2.8, 12, 1.5)
        ..close()
        ..moveTo(12, 4.4)
        ..cubicTo(13.8, 4.4, 14.6, 5.9, 14.6, 7.3)
        ..cubicTo(14.6, 9.1, 13.3, 10.3, 12, 10.3)
        ..cubicTo(10.7, 10.3, 9.4, 9.1, 9.4, 7.3)
        ..cubicTo(9.4, 5.9, 10.2, 4.4, 12, 4.4)
        ..close()
        ..moveTo(12, 10.3)
        ..lineTo(12, 22.5)
        ..moveTo(12, 13.2)
        ..lineTo(9.6, 11.6)
        ..moveTo(12, 13.2)
        ..lineTo(14.4, 11.6),
      fill: Path()
        ..moveTo(12, 6.1)
        ..cubicTo(12.8, 6.1, 13.1, 6.7, 13.1, 7.3)
        ..cubicTo(13.1, 8.1, 12.5, 8.6, 12, 8.6)
        ..cubicTo(11.5, 8.6, 10.9, 8.1, 10.9, 7.3)
        ..cubicTo(10.9, 6.7, 11.2, 6.1, 12, 6.1)
        ..close(),
    ),
    MantraSymbol.gada => _SymbolPaths(
      rotationDegrees: -35,
      stroke: Path()
        ..moveTo(12, 3.4)
        ..cubicTo(15.1, 3.4, 17.3, 5.9, 17.3, 8.8)
        ..cubicTo(17.3, 11.7, 15.1, 14, 12, 14)
        ..cubicTo(8.9, 14, 6.7, 11.7, 6.7, 8.8)
        ..cubicTo(6.7, 5.9, 8.9, 3.4, 12, 3.4)
        ..close()
        ..moveTo(7, 7.2)
        ..quadraticBezierTo(12, 8.8, 17, 7.2)
        ..moveTo(7, 10.4)
        ..quadraticBezierTo(12, 12, 17, 10.4)
        ..moveTo(10.8, 3.6)
        ..lineTo(12, 1.4)
        ..lineTo(13.2, 3.6)
        ..moveTo(12, 14)
        ..lineTo(12, 20.6)
        ..moveTo(10.2, 15.9)
        ..lineTo(13.8, 15.9),
      fill: Path()
        ..moveTo(12, 20)
        ..cubicTo(12.9, 20, 13.5, 20.7, 13.5, 21.5)
        ..cubicTo(13.5, 22.3, 12.8, 23, 12, 23)
        ..cubicTo(11.2, 23, 10.5, 22.3, 10.5, 21.5)
        ..cubicTo(10.5, 20.7, 11.1, 20, 12, 20)
        ..close(),
    ),
    MantraSymbol.trishul => _SymbolPaths(
      rotationDegrees: 0,
      stroke: Path()
        ..moveTo(12, 2.5)
        ..lineTo(12, 21.5)
        ..moveTo(10.4, 6.4)
        ..lineTo(12, 2.5)
        ..lineTo(13.6, 6.4)
        ..moveTo(12, 12)
        ..cubicTo(7.8, 12, 5.8, 9.6, 5.8, 5)
        ..moveTo(12, 12)
        ..cubicTo(16.2, 12, 18.2, 9.6, 18.2, 5)
        ..moveTo(4.6, 6.8)
        ..lineTo(5.8, 4.2)
        ..lineTo(7, 6.8)
        ..moveTo(17, 6.8)
        ..lineTo(18.2, 4.2)
        ..lineTo(19.4, 6.8)
        ..moveTo(10, 14.6)
        ..lineTo(14, 14.6),
      fill: null,
    ),
    MantraSymbol.diya => _SymbolPaths(
      rotationDegrees: 0,
      stroke: Path()
        ..moveTo(12, 3)
        ..cubicTo(15, 6.2, 15.2, 9.6, 12, 11.6)
        ..cubicTo(8.8, 9.6, 9, 6.2, 12, 3)
        ..close()
        ..moveTo(3.5, 13.8)
        ..lineTo(20.5, 13.8)
        ..cubicTo(19.9, 17.6, 16.4, 19.4, 12, 19.4)
        ..cubicTo(7.6, 19.4, 4.1, 17.6, 3.5, 13.8)
        ..close()
        ..moveTo(9.5, 21.6)
        ..lineTo(14.5, 21.6),
      fill: Path()
        ..moveTo(12, 6.8)
        ..cubicTo(13, 8, 13.1, 9.1, 12, 9.9)
        ..cubicTo(10.9, 9.1, 11, 8, 12, 6.8)
        ..close(),
    ),
    MantraSymbol.custom => _SymbolPaths(
      rotationDegrees: 0,
      stroke: Path()
        ..moveTo(12, 3.5)
        ..cubicTo(12.6, 8.6, 15.4, 11.4, 20.5, 12)
        ..cubicTo(15.4, 12.6, 12.6, 15.4, 12, 20.5)
        ..cubicTo(11.4, 15.4, 8.6, 12.6, 3.5, 12)
        ..cubicTo(8.6, 11.4, 11.4, 8.6, 12, 3.5)
        ..close(),
      fill: null,
    ),
  };
}

class _SymbolPaths {
  final double rotationDegrees;
  final Path stroke;
  final Path? fill;

  const _SymbolPaths({required this.rotationDegrees, required this.stroke, required this.fill});
}