import 'package:flutter/material.dart';

import '../../../app/console_widgets.dart';

/// 위치 핀 + "하차각 콘솔" 워드마크. 사이드바 머리·좁은 화면 앱바에.
class ConsoleBrand extends StatelessWidget {
  const ConsoleBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_pin, size: 20, color: c.accent),
        const SizedBox(width: 10),
        Text('하차각 콘솔', style: ConsoleFonts.wordmark.copyWith(color: c.textHi)),
      ],
    );
  }
}
