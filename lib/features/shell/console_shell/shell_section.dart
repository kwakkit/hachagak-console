import 'package:flutter/material.dart';

/// 셸 메뉴 항목 — 이름·아이콘·페이지.
class ShellSection {
  const ShellSection(this.label, this.icon, this.page);
  final String label;
  final IconData icon;
  final Widget page;
}
