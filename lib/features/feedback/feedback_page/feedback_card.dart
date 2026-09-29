import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/console_widgets.dart';
import '../feedback_item.dart';
import '../feedback_repository.dart';
import '../feedback_status.dart';
import 'category_tag.dart';

const _categoryLabels = {'bug': '오류', 'idea': '제안', 'etc': '기타'};

final _fmt = DateFormat('MM.dd HH:mm', 'ko');

/// 제보 한 건 — 접힘: 종류·요약·상태, 펼침: 전문·관리자 메모·상태 변경.
class FeedbackCard extends ConsumerStatefulWidget {
  const FeedbackCard({super.key, required this.item, required this.onChanged});

  final FeedbackItem item;
  final VoidCallback onChanged;

  @override
  ConsumerState<FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends ConsumerState<FeedbackCard> {
  late final _note = TextEditingController(text: widget.item.adminNote);
  late FeedbackStatus _status = widget.item.status;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await runWithSnack(
      context,
      () => ref
          .read(feedbackRepositoryProvider)
          .update(widget.item.id, _status, _note.text),
      success: '저장했습니다.',
    );
    if (ok) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    final item = widget.item;
    final meta = [
      _fmt.format(item.createdAt),
      if (item.appVersion != null) 'v${item.appVersion}',
      if (item.os != null) item.os!,
    ].join('  ·  ');

    return ConsolePanel(
      padding: EdgeInsets.zero,
      borderColor: item.status == FeedbackStatus.newOne
          ? c.alert.withValues(alpha: 0.35)
          : null,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(18, 8, 14, 8),
        title: Row(
          children: [
            CategoryTag(_categoryLabels[item.category] ?? item.category),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ConsoleFonts.label.copyWith(
                  color: c.textHi,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ConsoleFonts.monoSmall.copyWith(
              color: c.chromeDim,
              fontSize: 11,
            ),
          ),
        ),
        trailing: StatusPill(item.status.label, color: item.status.color(c)),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(color: c.hairline),
          const SizedBox(height: 14),
          SelectableText(
            item.message,
            style: ConsoleFonts.body13.copyWith(
              color: c.textHi,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: '관리자 메모'),
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              SegmentedButton<FeedbackStatus>(
                segments: [
                  for (final s in FeedbackStatus.values)
                    ButtonSegment(value: s, label: Text(s.label)),
                ],
                selected: {_status},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
              FilledButton(onPressed: _save, child: const Text('저장')),
            ],
          ),
        ],
      ),
    );
  }
}
