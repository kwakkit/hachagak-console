import 'package:flutter/material.dart';

/// 상태 점 — 은은한 정적 글로우(무한 애니메이션 없음: 테스트 `pumpAndSettle` 보호).
class ConsoleDot extends StatelessWidget {
  const ConsoleDot({super.key, required this.color, this.glow = true});

  final Color color;
  final bool glow;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: glow
          ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 6)]
          : null,
    ),
  );
}
