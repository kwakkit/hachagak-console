import 'package:flutter/material.dart';

import '../../../app/console_widgets.dart';

/// 수치 패널 하나 — 라벨 + 큰 mono 숫자.
class StatTile extends StatelessWidget {
  const StatTile(this.label, this.value, this.icon, {super.key, this.accent});

  final String label;
  final String value;
  final IconData icon;

  /// 주의가 필요할 때만 색. 평소엔 무채색.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return ConsolePanel(
      borderColor: accent?.withValues(alpha: 0.5),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent ?? c.chromeDim),
              const SizedBox(width: 6),
              Text(label, style: ConsoleFonts.body13.copyWith(color: c.textLo)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: ConsoleFonts.readout.copyWith(color: accent ?? c.textHi),
          ),
        ],
      ),
    );
  }
}
