import 'package:flutter/material.dart';

/// Islomiy geometrik naqsh: takrorlanuvchi sakkiz uchli yulduzlar
/// (ikki aylantirilgan kvadrat). Bezak sifatida ishlatiladi.
class IslamicPattern extends StatelessWidget {
  final Color color;
  final double cell;
  final double strokeWidth;

  const IslamicPattern({
    super.key,
    required this.color,
    this.cell = 44,
    this.strokeWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: CustomPaint(
          painter: _PatternPainter(color, cell, strokeWidth),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;
  final double cell;
  final double strokeWidth;

  const _PatternPainter(this.color, this.cell, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    final half = cell * 0.36;
    final square = Rect.fromLTRB(-half, -half, half, half);
    for (double y = cell / 2; y < size.height + cell; y += cell) {
      for (double x = cell / 2; x < size.width + cell; x += cell) {
        canvas.save();
        canvas.translate(x, y);
        canvas.drawRect(square, paint);
        canvas.rotate(0.7853981634);
        canvas.drawRect(square, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.color != color || old.cell != cell || old.strokeWidth != strokeWidth;
}
