import 'package:flutter/material.dart';

import '../../../app/console_widgets.dart';
import 'shell_section.dart';

/// 사이드바 메뉴 한 줄 — 선택되면 보라 칠 + 왼쪽 막대.
class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final ShellSection section;
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
