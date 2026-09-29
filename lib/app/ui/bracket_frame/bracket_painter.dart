import 'package:flutter/material.dart';

/// [BracketFrame] 의 네 모서리 ㄱ자 선. 자식보다 6px 바깥에 그린다.
class BracketPainter extends CustomPainter {
  const BracketPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const len = 16.0;
    const inset = -6.0;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final l = inset, t = inset;
    final r = size.width - inset, b = size.height - inset;
    for (final (x, y, dx, dy) in [
      (l, t, 1.0, 1.0),
      (r, t, -1.0, 1.0),
      (l, b, 1.0, -1.0),
      (r, b, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(Offset(x, y), Offset(x + len * dx, y), paint)
        ..drawLine(Offset(x, y), Offset(x, y + len * dy), paint);
    }
  }

  @override
  bool shouldRepaint(BracketPainter old) => old.color != color;
}
