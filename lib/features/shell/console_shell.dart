import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/console_widgets.dart';
import '../../core/env.dart';
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

const _wideBreakpoint = 720.0;

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
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final page = ConsoleBackdrop(child: _sections[_index].page);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(selected: _index, onSelect: _select),
            Expanded(child: page),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const _Brand(),
        actions: const [_ThemeToggle(), _SignOut(), SizedBox(width: 4)],
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

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.hub_outlined, size: 20, color: c.accent),
        const SizedBox(width: 10),
        Text('곽킷 콘솔', style: ConsoleFonts.wordmark.copyWith(color: c.textHi)),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    final email = Env.isConfigured ? db.auth.currentUser?.email : null;
    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(right: BorderSide(color: c.hairline)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 22),
              child: _Brand(),
            ),
            Divider(color: c.hairline),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: const ConsoleEyebrow('App'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: c.panel2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.hairline),
                ),
                child: Row(
                  children: [
                    ConsoleDot(color: c.ok),
                    const SizedBox(width: 10),
                    Text(
                      '하차각',
                      style: ConsoleFonts.label.copyWith(color: c.textHi),
                    ),
                    const Spacer(),
                    Text(
                      'hachagak',
                      style: ConsoleFonts.monoSmall.copyWith(
                        color: c.textLo,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: const ConsoleEyebrow('Menu'),
            ),
            for (final (i, s) in _sections.indexed)
              _NavItem(
                section: s,
                selected: i == selected,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            Divider(color: c.hairline),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      email ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: ConsoleFonts.monoSmall.copyWith(
                        color: c.textLo,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const _ThemeToggle(),
                  const _SignOut(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final _Section section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    final fg = selected ? c.textHi : c.textLo;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? c.accent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? c.accent : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  section.icon,
                  size: 19,
                  color: selected ? c.accent : c.chrome,
                ),
                const SizedBox(width: 12),
                Text(
                  section.label,
                  style: ConsoleFonts.body13.copyWith(
                    color: fg,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return IconButton(
      tooltip: dark ? '라이트 모드' : '다크 모드',
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}

class _SignOut extends StatelessWidget {
  const _SignOut();

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: '로그아웃',
    icon: const Icon(Icons.logout),
    onPressed: () => db.auth.signOut(),
  );
}

/// 각 페이지 공통 레이아웃: 아이브로우 + 제목 + 우측 액션 + 본문.
/// 넓은 화면에선 본문 폭을 제한해 긴 줄을 피한다.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.child,
    this.actions = const [],
  });

  final String title;

  /// 제목 위 mono 라벨 (예: `Overview`).
  final String eyebrow;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            wide ? 32 : 16,
            wide ? 28 : 12,
            wide ? 32 : 16,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 16,
                runSpacing: 12,
                children: [
                  if (wide)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConsoleEyebrow(eyebrow),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: ConsoleFonts.pageTitle.copyWith(
                            color: c.textHi,
                          ),
                        ),
                      ],
                    ),
                  if (actions.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: actions,
                    ),
                ],
              ),
              SizedBox(height: wide ? 24 : 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
