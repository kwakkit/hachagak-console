import 'package:flutter/material.dart';

import '../../../app/console_widgets.dart';
import '../notice.dart';

/// 공지 한 줄 — 상태 배지(게시 중·예약·종료)·제목·본문 요약·기간.
class NoticeRow extends StatelessWidget {
  const NoticeRow({
    super.key,
    required this.notice,
    required this.onEdit,
    required this.onDelete,
  });

  final Notice notice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    final n = notice;
    final (label, color) = n.isLive
        ? ('게시 중', c.ok)
        : n.isScheduled
        ? ('예약', c.warn)
        : ('종료', c.chromeDim);
    final period =
        '${noticeTimeFormat.format(n.startsAt)}  →  ${n.endsAt == null ? '계속' : noticeTimeFormat.format(n.endsAt!)}';

    return ConsolePanel(
      onTap: onEdit,
      borderColor: n.isLive ? c.ok.withValues(alpha: 0.35) : null,
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(label, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        n.title,
                        overflow: TextOverflow.ellipsis,
                        style: ConsoleFonts.label.copyWith(color: c.textHi),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  n.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ConsoleFonts.body13.copyWith(color: c.textLo),
                ),
                const SizedBox(height: 6),
                Text(
                  period,
                  style: ConsoleFonts.monoSmall.copyWith(color: c.chromeDim),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '삭제',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
