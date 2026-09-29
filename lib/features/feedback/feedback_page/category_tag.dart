import 'package:flutter/material.dart';

import '../../../app/console_widgets.dart';

/// 제보 종류 태그 (오류·제안·기타).
class CategoryTag extends StatelessWidget {
  const CategoryTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.hairline),
      ),
      child: Text(
        label,
        style: ConsoleFonts.eyebrow.copyWith(
          color: c.chrome,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
