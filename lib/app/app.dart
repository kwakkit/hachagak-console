import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env.dart';
import '../core/supabase.dart';
import '../features/auth/login_page.dart';
import '../features/shell/console_shell.dart';
import 'console_widgets.dart';

class ConsoleApp extends ConsumerWidget {
  const ConsoleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '곽킷 콘솔',
      debugShowCheckedModeBanner: false,
      theme: consoleTheme(Brightness.light),
      darkTheme: consoleTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
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
          error: (e, _) => _Message(
            title: '관리자 확인 실패',
            body: '$e',
            color: context.console.alert,
            showSignOut: true,
          ),
          data: (isAdmin) => isAdmin
              ? const ConsoleShell()
              : _Message(
                  title: '접근 권한 없음',
                  body: '관리자로 등록되지 않은 계정입니다.',
                  color: context.console.warn,
                  showSignOut: true,
                ),
        );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: ConsoleBackdrop(child: Center(child: CircularProgressIndicator())),
  );
}

/// 가운데 브라켓 패널 하나짜리 안내 화면.
class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.body,
    required this.color,
    this.showSignOut = false,
  });

  final String title;
  final String body;
  final Color color;
  final bool showSignOut;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return Scaffold(
      body: ConsoleBackdrop(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BracketFrame(
                child: ConsolePanel(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusPill(title, color: color),
                      const SizedBox(height: 16),
                      SelectableText(
                        body,
                        style: ConsoleFonts.body13.copyWith(
                          color: c.textHi,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      if (showSignOut) ...[
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () => db.auth.signOut(),
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('로그아웃'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupNeeded extends StatelessWidget {
  const _SetupNeeded();

  @override
  Widget build(BuildContext context) => _Message(
    title: 'Supabase 설정이 없습니다',
    body:
        'dart_defines/local.json 에 SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY 를 넣고 '
        '다시 실행하세요.\n\n'
        'flutter run -d chrome --dart-define-from-file=dart_defines/local.json',
    color: context.console.warn,
  );
}
