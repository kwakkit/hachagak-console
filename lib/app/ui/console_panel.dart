import 'package:flutter/material.dart';

import '../theme/console_theme.dart';

/// 패널 — 카드 대신 쓰는 기본 컨테이너. [onTap] 이 있으면 누를 수 있다.
class ConsolePanel extends StatelessWidget {
  const ConsolePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    final radius = BorderRadius.circular(14);
    return Material(
      color: c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor ?? c.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
    );
  }
}
