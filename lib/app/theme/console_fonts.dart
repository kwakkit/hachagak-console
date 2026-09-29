import 'package:flutter/painting.dart';

/// "관제실 콘솔" 폰트 — 색 없는 스타일 상수(색은 `context.console` 로 입힌다).
/// pubspec `fonts:` 패밀리명과 일치해야 한다. 한글 본문 폰트는 웹 용량 때문에
/// KS X 1001 한글 2,350자 + 라틴·기호로 서브셋했다(없는 글자는 브라우저 폴백).
abstract final class ConsoleFonts {
  const ConsoleFonts._();

  /// 워드마크·페이지 제목 — 한글 지원 테크 서체.
  static const String display = 'Orbit';

  /// 본문.
  static const String body = 'IBMPlexSansKR';

  /// 수치·키·타임스탬프 — 숫자 폭 고정.
  static const String mono = 'IBMPlexMono';

  /// mono 에 한글이 없어 섞이면 본문 폰트로 떨어지게.
  static const List<String> _monoFallback = [body];

  static const TextStyle wordmark = TextStyle(
    fontFamily: display,
    fontSize: 17,
    letterSpacing: 0.6,
  );

  static const TextStyle pageTitle = TextStyle(
    fontFamily: display,
    fontSize: 22,
    letterSpacing: 0.4,
  );

  static const TextStyle eyebrow = TextStyle(
    fontFamily: mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 10.5,
    letterSpacing: 1.6,
  );

  static const TextStyle label = TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body13 = TextStyle(fontFamily: body, fontSize: 13);

  static const TextStyle monoSmall = TextStyle(
    fontFamily: mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 12,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle readout = TextStyle(
    fontFamily: mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
