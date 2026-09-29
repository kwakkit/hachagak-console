import 'package:flutter/material.dart';

import '../theme/console_theme.dart';
import 'console_backdrop/scanline_painter.dart';

/// 화면 배경 — void 바탕에 아주 옅은 스캔라인.
class ConsoleBackdrop extends StatelessWidget {
  const ConsoleBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.void_),
      child: CustomPaint(painter: ScanlinePainter(c.scanline), child: child),
    );
  }
}
