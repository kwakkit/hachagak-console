import 'package:flutter/material.dart';

import '../../../app/console_widgets.dart';
import '../../../core/env.dart';
import '../../../core/supabase.dart';
import 'console_brand.dart';
import 'nav_item.dart';
import 'shell_section.dart';
import 'sign_out_button.dart';
import 'theme_toggle.dart';

/// 넓은 화면의 좌측 사이드바 — 워드마크, 메뉴, 로그인 계정·테마·로그아웃.
class ShellSidebar extends StatelessWidget {
  const ShellSidebar({
    super.key,
    required this.sections,
    required this.selected,
    required this.onSelect,
  });

  final List<ShellSection> sections;
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
              child: ConsoleBrand(),
            ),
            Divider(color: c.hairline),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: const ConsoleEyebrow('Menu'),
            ),
            for (final (i, s) in sections.indexed)
              NavItem(
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
                  const ThemeToggle(),
                  const SignOutButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
