import 'package:flutter/material.dart';

import '../../core/supabase.dart';
import '../config/config_page.dart';
import '../dashboard/dashboard_page.dart';
import '../feedback/feedback_page.dart';
import '../notices/notices_page.dart';

class _Section {
  const _Section(this.label, this.icon, this.page);
  final String label;
  final IconData icon;
  final Widget page;
}

const _sections = [
  _Section('대시보드', Icons.insights_outlined, DashboardPage()),
  _Section('공지', Icons.campaign_outlined, NoticesPage()),
  _Section('원격 설정', Icons.tune, ConfigPage()),
  _Section('제보함', Icons.inbox_outlined, FeedbackPage()),
];

/// 넓은 화면은 NavigationRail, 좁은 화면은 하단 NavigationBar.
class ConsoleShell extends StatefulWidget {
  const ConsoleShell({super.key});

  @override
  State<ConsoleShell> createState() => _ConsoleShellState();
}

class _ConsoleShellState extends State<ConsoleShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final section = _sections[_index];
    final signOut = IconButton(
      tooltip: '로그아웃',
      icon: const Icon(Icons.logout),
      onPressed: () => db.auth.signOut(),
    );

    return Scaffold(
      appBar: wide
          ? null
          : AppBar(title: Text(section.label), actions: [signOut]),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '곽킷',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: signOut,
                  ),
                ),
              ),
              destinations: [
                for (final s in _sections)
                  NavigationRailDestination(
                    icon: Icon(s.icon),
                    label: Text(s.label),
                  ),
              ],
            ),
          if (wide) const VerticalDivider(width: 1),
          Expanded(child: section.page),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final s in _sections)
                  NavigationDestination(icon: Icon(s.icon), label: s.label),
              ],
            ),
    );
  }
}

/// 각 페이지 공통 레이아웃: 제목 + 우측 액션 + 본문.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return Padding(
      padding: EdgeInsets.all(wide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (wide)
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              ...actions,
            ],
          ),
          SizedBox(height: wide ? 16 : 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}
