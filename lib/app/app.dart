import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env.dart';
import '../core/supabase.dart';
import '../features/auth/login_page.dart';
import '../features/shell/console_shell.dart';

/// 하차각 브랜드 시드와 맞춘다 (hacha-gak/lib/app/theme/app_colors.dart).
const _seed = Color(0xFF6C3AE0);

class ConsoleApp extends StatelessWidget {
  const ConsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: b),
      useMaterial3: true,
    );
    return MaterialApp(
      title: '곽킷 콘솔',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: Env.isConfigured ? const _AuthGate() : const _SetupNeeded(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session.isLoading) return const _Loading();
    if (session.value == null) return const LoginPage();

    return ref
        .watch(isAdminProvider)
        .when(
          loading: () => const _Loading(),
          error: (e, _) => _Message('관리자 확인 실패: $e'),
          data: (isAdmin) => isAdmin
              ? const ConsoleShell()
              : const _Message('관리자 권한이 없는 계정입니다.', showSignOut: true),
        );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.showSignOut = false});

  final String text;
  final bool showSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          if (showSignOut) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => db.auth.signOut(),
              child: const Text('로그아웃'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _SetupNeeded extends StatelessWidget {
  const _SetupNeeded();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Supabase 설정이 없습니다.\n'
          'dart_defines/local.json 에 SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY 를 넣고\n'
          'flutter run -d chrome --dart-define-from-file=dart_defines/local.json',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
