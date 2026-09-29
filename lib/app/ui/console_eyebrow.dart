import 'package:flutter/material.dart';

import '../theme/console_theme.dart';

/// mono 대문자 섹션 라벨. (예: "TODAY · 오늘")
class ConsoleEyebrow extends StatelessWidget {
  const ConsoleEyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: ConsoleFonts.eyebrow.copyWith(
      color: color ?? context.console.chromeDim,
    ),
  );
}
