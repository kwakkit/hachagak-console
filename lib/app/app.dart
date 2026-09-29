import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env.dart';
import 'gate/auth_gate.dart';
import 'gate/setup_needed.dart';
import 'console_widgets.dart';

class ConsoleApp extends ConsumerWidget {
  const ConsoleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '하차각 콘솔',
      debugShowCheckedModeBanner: false,
      theme: consoleTheme(Brightness.light),
      darkTheme: consoleTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      home: Env.isConfigured ? const AuthGate() : const SetupNeeded(),
    );
  }
}
