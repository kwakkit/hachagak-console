import 'package:flutter/material.dart';

/// "관제실 콘솔" 색 토큰 — 하차각(`hacha-gak/lib/app/ui/console/console_palette.dart`)과
/// 같은 값. 다크 = 야간 관제실, 라이트 = 청사진(흰 도면지 + 스틸블루 잉크).
///
/// 크롬(테두리·아이콘·라벨)은 채도 뺀 청회색 [chrome] 하나로 통일하고, 색은
/// 의미가 있는 곳 — 브랜드 강조([accent]), 상태([ok]/[warn]/[alert]) — 에만 쓴다.
@immutable
class ConsolePalette extends ThemeExtension<ConsolePalette> {
  const ConsolePalette({
    required this.void_,
    required this.panel,
    required this.panel2,
    required this.hairline,
    required this.chrome,
    required this.chromeDim,
    required this.textHi,
    required this.textLo,
    required this.scanline,
    required this.accent,
    required this.ok,
    required this.warn,
    required this.alert,
    required this.isDark,
  });

  /// 화면 바탕.
  final Color void_;

  /// 패널·카드 칠.
  final Color panel;

  /// 살짝 도드라진 칠(인풋·선택된 내비·표 머리).
  final Color panel2;

  /// 구분선·테두리.
  final Color hairline;

  /// 중립 크롬 — 아이콘·보조 강조.
  final Color chrome;

  /// 더 옅은 크롬 — 아이브로우 라벨.
  final Color chromeDim;

  final Color textHi;
  final Color textLo;

  /// 배경 스캔라인 베이스색(알파는 그리는 쪽에서).
  final Color scanline;

  /// 브랜드 보라 — 주 버튼·선택 표시·핵심 수치.
  final Color accent;

  /// 상태: 게시 중·완료 / 확인 중·예약 / 새 제보·오류.
  final Color ok;
  final Color warn;
  final Color alert;

  final bool isDark;

  static const ConsolePalette dark = ConsolePalette(
    void_: Color(0xFF0B0F14),
    panel: Color(0xFF121920),
    panel2: Color(0xFF182129),
    hairline: Color(0xFF25323C),
    chrome: Color(0xFF7791A1),
    chromeDim: Color(0xFF557080),
    textHi: Color(0xFFE9EEF1),
    textLo: Color(0xFF8A9BA6),
    scanline: Color(0xFFE9EEF1),
    accent: Color(0xFFB9A5FF),
    ok: Color(0xFF5FD3A0),
    warn: Color(0xFFF2C166),
    alert: Color(0xFFFF7A85),
    isDark: true,
  );

  static const ConsolePalette light = ConsolePalette(
    void_: Color(0xFFEEF1F4),
    panel: Color(0xFFFFFFFF),
    panel2: Color(0xFFF3F5F8),
    hairline: Color(0xFFD3DBE2),
    chrome: Color(0xFF4A6273),
    chromeDim: Color(0xFF5C7080),
    textHi: Color(0xFF16202A),
    textLo: Color(0xFF54626D),
    scanline: Color(0xFF16202A),
    accent: Color(0xFF5A2FBF),
    ok: Color(0xFF16875A),
    warn: Color(0xFF9A6700),
    alert: Color(0xFFC62836),
    isDark: false,
  );

  static ConsolePalette resolve(Brightness b) =>
      b == Brightness.dark ? dark : light;

  @override
  ConsolePalette copyWith() => this;

  @override
  ConsolePalette lerp(
    covariant ThemeExtension<ConsolePalette>? other,
    double t,
  ) {
    if (other is! ConsolePalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return ConsolePalette(
      void_: l(void_, other.void_),
      panel: l(panel, other.panel),
      panel2: l(panel2, other.panel2),
      hairline: l(hairline, other.hairline),
      chrome: l(chrome, other.chrome),
      chromeDim: l(chromeDim, other.chromeDim),
      textHi: l(textHi, other.textHi),
      textLo: l(textLo, other.textLo),
      scanline: l(scanline, other.scanline),
      accent: l(accent, other.accent),
      ok: l(ok, other.ok),
      warn: l(warn, other.warn),
      alert: l(alert, other.alert),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension ConsolePaletteX on BuildContext {
  /// `context.console.textHi` 처럼 쓴다. 테마 밖이면 다크로 떨어진다.
  ConsolePalette get console =>
      Theme.of(this).extension<ConsolePalette>() ?? ConsolePalette.dark;
}
