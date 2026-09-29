import 'package:flutter/material.dart';

import '../console_widgets.dart';

/// 세션·권한 확인 중 전체 화면 로딩.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: ConsoleBackdrop(child: Center(child: CircularProgressIndicator())),
  );
}
