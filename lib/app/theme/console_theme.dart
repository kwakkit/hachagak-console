import 'package:flutter/material.dart';

import 'console_fonts.dart';
import 'console_palette.dart';

export 'console_fonts.dart';
export 'console_palette.dart';

/// 앱 전역 Material 테마 — 기본 위젯(버튼·인풋·다이얼로그·표·스낵바…)이
/// 따로 손대지 않아도 콘솔 톤이 되게 한다. 콘솔 전용 위젯은 `console_widgets.dart`.
ThemeData consoleTheme(Brightness brightness) {
  final p = ConsolePalette.resolve(brightness);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.accent,
    onPrimary: p.isDark ? p.void_ : Colors.white,
    primaryContainer: p.accent.withValues(alpha: 0.16),
    onPrimaryContainer: p.textHi,
    secondary: p.chrome,
    onSecondary: p.void_,
    secondaryContainer: p.panel2,
    onSecondaryContainer: p.textHi,
    surface: p.panel,
    onSurface: p.textHi,
    onSurfaceVariant: p.textLo,
    surfaceContainerLowest: p.void_,
    surfaceContainerLow: p.panel,
    surfaceContainer: p.panel,
    surfaceContainerHigh: p.panel2,
    surfaceContainerHighest: p.panel2,
    outline: p.chromeDim,
    outlineVariant: p.hairline,
    error: p.alert,
    onError: p.isDark ? p.void_ : Colors.white,
    inverseSurface: p.textHi,
    onInverseSurface: p.void_,
  );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c, width: w),
  );
  final radius = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
  );
  const buttonText = TextStyle(
    fontFamily: ConsoleFonts.body,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
  );

  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: ConsoleFonts.body,
    scaffoldBackgroundColor: p.void_,
    canvasColor: p.panel,
    splashColor: p.chrome.withValues(alpha: 0.10),
    highlightColor: p.chrome.withValues(alpha: 0.06),
    hoverColor: p.chrome.withValues(alpha: 0.06),
    iconTheme: IconThemeData(color: p.chrome, size: 20),
    dividerTheme: DividerThemeData(color: p.hairline, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: p.void_,
      foregroundColor: p.textHi,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: ConsoleFonts.wordmark.copyWith(color: p.textHi),
      shape: Border(bottom: BorderSide(color: p.hairline)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.panel,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.accent.withValues(alpha: 0.18),
      labelTextStyle: WidgetStatePropertyAll(
        ConsoleFonts.body13.copyWith(fontSize: 12, color: p.textHi),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: p.panel2,
        disabledForegroundColor: p.textLo,
        textStyle: buttonText,
        shape: radius,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textHi,
        side: BorderSide(color: p.hairline),
        textStyle: buttonText,
        shape: radius,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.chrome,
        textStyle: buttonText,
        shape: radius,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: p.panel,
        foregroundColor: p.textLo,
        selectedBackgroundColor: p.accent.withValues(alpha: 0.16),
        selectedForegroundColor: p.textHi,
        side: BorderSide(color: p.hairline),
        textStyle: buttonText.copyWith(fontSize: 12.5),
        shape: radius,
        visualDensity: VisualDensity.compact,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : p.chrome,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accent : p.panel2,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accent : p.hairline,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.panel2,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: TextStyle(color: p.textLo),
      floatingLabelStyle: TextStyle(color: p.chrome),
      hintStyle: TextStyle(color: p.textLo),
      helperStyle: TextStyle(color: p.textLo, fontSize: 12),
      border: border(p.hairline),
      enabledBorder: border(p.hairline),
      focusedBorder: border(p.accent, 1.5),
      errorBorder: border(p.alert),
      focusedErrorBorder: border(p.alert, 1.5),
    ),
    listTileTheme: ListTileThemeData(textColor: p.textHi, iconColor: p.chrome),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: p.chrome,
      collapsedIconColor: p.chromeDim,
      shape: const Border(),
      collapsedShape: const Border(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.hairline),
      ),
      titleTextStyle: ConsoleFonts.wordmark.copyWith(color: p.textHi),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.panel,
      surfaceTintColor: Colors.transparent,
    ),
    timePickerTheme: TimePickerThemeData(backgroundColor: p.panel),
    popupMenuTheme: PopupMenuThemeData(
      color: p.panel2,
      surfaceTintColor: Colors.transparent,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(p.panel2),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(p.panel2),
      headingTextStyle: ConsoleFonts.eyebrow.copyWith(color: p.chromeDim),
      dataTextStyle: ConsoleFonts.monoSmall.copyWith(
        color: p.textHi,
        fontSize: 13,
      ),
      dividerThickness: 1,
      headingRowHeight: 40,
      dataRowMinHeight: 44,
      dataRowMaxHeight: 44,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.textHi,
      contentTextStyle: ConsoleFonts.body13.copyWith(color: p.void_),
      shape: radius,
      width: 420,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: p.textHi,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: ConsoleFonts.body13.copyWith(color: p.void_, fontSize: 12),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
    extensions: [p],
  );
}
