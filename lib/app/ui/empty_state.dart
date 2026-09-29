import 'package:flutter/material.dart';

import '../theme/console_theme.dart';

/// 빈 상태 — 아이콘 + 안내.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: c.chromeDim),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ConsoleFonts.body13.copyWith(color: c.textLo),
            ),
          ],
        ),
      ),
    );
  }
}
