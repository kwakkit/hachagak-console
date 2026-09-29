import 'package:flutter/material.dart';

import '../theme/console_theme.dart';
import 'console_eyebrow.dart';

/// 이 폭 이상이면 넓은 레이아웃(사이드바·큰 제목).
const wideBreakpoint = 720.0;

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
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
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
