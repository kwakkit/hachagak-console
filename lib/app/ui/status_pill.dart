import 'package:flutter/material.dart';

import '../theme/console_theme.dart';
import 'console_dot.dart';

/// 상태 배지 — 점 + mono 라벨, 옅은 색 칠.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConsoleDot(color: color, glow: false),
        const SizedBox(width: 6),
        Text(
          label,
          style: ConsoleFonts.eyebrow.copyWith(
            color: color,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
