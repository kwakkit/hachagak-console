import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/console_theme.dart';

export 'theme/console_theme.dart';

/// 하차각과 같이 라이트(청사진)가 기본, 다크(야간 관제실)는 셸의 토글로. 새로고침하면 기본값.
final themeModeProvider = NotifierProvider<_ThemeMode, ThemeMode>(
  _ThemeMode.new,
);

class _ThemeMode extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() =>
      state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}

/// 화면 배경 — void 바탕에 아주 옅은 스캔라인.
class ConsoleBackdrop extends StatelessWidget {
  const ConsoleBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.void_),
      child: CustomPaint(painter: _Scanlines(c.scanline), child: child),
    );
  }
}

class _Scanlines extends CustomPainter {
  const _Scanlines(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.018)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_Scanlines old) => old.color != color;
}

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

/// mono 대문자 섹션 라벨. (예: "TODAY · 오늘")
class ConsoleEyebrow extends StatelessWidget {
  const ConsoleEyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: ConsoleFonts.eyebrow.copyWith(
      color: color ?? context.console.chromeDim,
    ),
  );
}

/// 상태 점 — 은은한 정적 글로우(무한 애니메이션 없음: 테스트 `pumpAndSettle` 보호).
class ConsoleDot extends StatelessWidget {
  const ConsoleDot({super.key, required this.color, this.glow = true});

  final Color color;
  final bool glow;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: glow
          ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 6)]
          : null,
    ),
  );
}

/// 상태 배지 — 점 + mono 라벨, 옅은 색 칠.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConsoleDot(color: color, glow: false),
        const SizedBox(width: 6),
        Text(
          label,
          style: ConsoleFonts.eyebrow.copyWith(
            color: color,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// 네 모서리 브라켓 — 관제실 HUD 프레임. 로그인 패널 등 "주목" 영역에.
class BracketFrame extends StatelessWidget {
  const BracketFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _Brackets(context.console.chrome),
    child: child,
  );
}

class _Brackets extends CustomPainter {
  const _Brackets(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const len = 16.0;
    const inset = -6.0;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final l = inset, t = inset;
    final r = size.width - inset, b = size.height - inset;
    for (final (x, y, dx, dy) in [
      (l, t, 1.0, 1.0),
      (r, t, -1.0, 1.0),
      (l, b, 1.0, -1.0),
      (r, b, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(Offset(x, y), Offset(x + len * dx, y), paint)
        ..drawLine(Offset(x, y), Offset(x, y + len * dy), paint);
    }
  }

  @override
  bool shouldRepaint(_Brackets old) => old.color != color;
}

/// 빈 상태 — 아이콘 + 안내.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: c.chromeDim),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ConsoleFonts.body13.copyWith(color: c.textLo),
            ),
          ],
        ),
      ),
    );
  }
}
