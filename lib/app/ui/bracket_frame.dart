import 'package:flutter/material.dart';

import '../theme/console_theme.dart';
import 'bracket_frame/bracket_painter.dart';

/// 네 모서리 브라켓 — 관제실 HUD 프레임. 로그인 패널 등 "주목" 영역에.
class BracketFrame extends StatelessWidget {
  const BracketFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: BracketPainter(context.console.chrome),
    child: child,
  );
}
