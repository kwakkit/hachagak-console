import 'package:flutter/material.dart';

import '../console_widgets.dart';
import 'message_screen.dart';

/// `dart_defines/local.json` 에 Supabase 값이 없을 때.
class SetupNeeded extends StatelessWidget {
  const SetupNeeded({super.key});

  @override
  Widget build(BuildContext context) => MessageScreen(
    title: 'Supabase 설정이 없습니다',
    body:
        'dart_defines/local.json 에 SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY 를 넣고 '
        '다시 실행하세요.\n\n'
        'flutter run -d chrome --dart-define-from-file=dart_defines/local.json',
    color: context.console.warn,
  );
}
