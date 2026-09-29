import 'package:flutter/material.dart';

import '../../../app/console_widgets.dart';

/// 로그인 화면 머리 — 위치 핀 + "하차각 콘솔" + 영문 부제.
class LoginWordmark extends StatelessWidget {
  const LoginWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return Column(
      children: [
        Icon(Icons.location_pin, size: 32, color: c.accent),
        const SizedBox(height: 12),
        Text(
          '하차각 콘솔',
          style: ConsoleFonts.pageTitle.copyWith(color: c.textHi, fontSize: 26),
        ),
        const SizedBox(height: 6),
        ConsoleEyebrow('Hachagak · Operations Console', color: c.chrome),
      ],
    );
  }
}
