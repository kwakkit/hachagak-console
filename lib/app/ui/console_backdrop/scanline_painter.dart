import 'package:flutter/material.dart';

/// [ConsoleBackdrop] 배경의 3px 간격 옅은 가로줄.
class ScanlinePainter extends CustomPainter {
  const ScanlinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.018)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(ScanlinePainter old) => old.color != color;
}
