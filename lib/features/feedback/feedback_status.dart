import 'package:flutter/material.dart';

import '../../app/theme/console_palette.dart';

/// 제보 처리 상태 — 콘솔 `feedback.status` check 제약과 같은 값.
enum FeedbackStatus {
  newOne('new', '새 제보'),
  checking('checking', '확인 중'),
  done('done', '완료');

  const FeedbackStatus(this.value, this.label);
  final String value;
  final String label;

  static FeedbackStatus parse(String v) =>
      values.firstWhere((s) => s.value == v, orElse: () => newOne);

  Color color(ConsolePalette c) => switch (this) {
    newOne => c.alert,
    checking => c.warn,
    done => c.ok,
  };
}
