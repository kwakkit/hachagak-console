import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase.dart';
import '../../features/auth/login_page.dart';
import '../../features/shell/console_shell.dart';
import '../console_widgets.dart';
import 'loading_screen.dart';
import 'message_screen.dart';

/// 세션 → 관리자 여부 순으로 확인해 로그인·셸·차단 화면 중 하나를 띄운다.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session.isLoading) return const LoadingScreen();
    if (session.value == null) return const LoginPage();

    return ref
        .watch(isAdminProvider)
        .when(
          loading: () => const LoadingScreen(),
          error: (e, _) => MessageScreen(
            title: '관리자 확인 실패',
            body: '$e',
            color: context.console.alert,
            showSignOut: true,
          ),
          data: (isAdmin) => isAdmin
              ? const ConsoleShell()
              : MessageScreen(
                  title: '접근 권한 없음',
                  body: '관리자로 등록되지 않은 계정입니다.',
                  color: context.console.warn,
                  showSignOut: true,
                ),
        );
  }
}
