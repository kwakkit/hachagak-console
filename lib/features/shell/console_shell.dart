import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/console_widgets.dart';
import '../config/config_page.dart';
import '../dashboard/dashboard_page.dart';
import '../feedback/feedback_page.dart';
import '../notices/notices_page.dart';
import 'console_shell/console_brand.dart';
import 'console_shell/shell_section.dart';
import 'console_shell/shell_sidebar.dart';
import 'console_shell/sign_out_button.dart';
import 'console_shell/theme_toggle.dart';

const _sections = <ShellSection>[
  ShellSection('대시보드', Icons.insights_outlined, DashboardPage()),
  ShellSection('공지', Icons.campaign_outlined, NoticesPage()),
  ShellSection('원격 설정', Icons.tune, ConfigPage()),
  ShellSection('제보함', Icons.inbox_outlined, FeedbackPage()),
];

/// 넓은 화면은 좌측 사이드바, 좁은 화면은 상단 바 + 하단 NavigationBar.
class ConsoleShell extends ConsumerStatefulWidget {
  const ConsoleShell({super.key});

  @override
  ConsumerState<ConsoleShell> createState() => _ConsoleShellState();
}

class _ConsoleShellState extends ConsumerState<ConsoleShell> {
  int _index = 0;

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final page = ConsoleBackdrop(child: _sections[_index].page);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            ShellSidebar(
              sections: _sections,
              selected: _index,
              onSelect: _select,
            ),
            Expanded(child: page),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const ConsoleBrand(),
        actions: const [ThemeToggle(), SignOutButton(), SizedBox(width: 4)],
      ),
      body: page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (final s in _sections)
            NavigationDestination(icon: Icon(s.icon), label: s.label),
        ],
      ),
    );
  }
}
