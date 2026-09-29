import 'package:flutter/material.dart';

import '../../../app/console_widgets.dart';
import '../config_entry.dart';

/// 알려진 키의 사람용 이름. 모르는 키는 키 그대로.
const _titles = {
  'min_version': '최소 지원 버전',
  'latest_version': '최신 버전',
  'realtime_enabled': '실시간 열차 매칭 (방법 A)',
};

/// 왼쪽: 이름 + mono 키 + 설명, 오른쪽: 컨트롤. 좁으면 아래로 내린다.
class EntryLayout extends StatelessWidget {
  const EntryLayout({super.key, required this.entry, required this.trailing});

  final ConfigEntry entry;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _titles[entry.key] ?? entry.key,
          style: ConsoleFonts.label.copyWith(color: c.textHi),
        ),
        const SizedBox(height: 4),
        Text(
          entry.key,
          style: ConsoleFonts.monoSmall.copyWith(color: c.chromeDim),
        ),
        if (entry.description != null) ...[
          const SizedBox(height: 8),
          Text(
            entry.description!,
            style: ConsoleFonts.body13.copyWith(color: c.textLo),
          ),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 560
          ? Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 16),
                trailing,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: trailing),
              ],
            ),
    );
  }
}
