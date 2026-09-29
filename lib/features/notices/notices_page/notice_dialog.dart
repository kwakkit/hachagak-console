import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/console_widgets.dart';
import '../notice.dart';
import '../notices_repository.dart';

/// 공지 작성·수정 다이얼로그. 저장하면 `true` 로 닫힌다.
class NoticeDialog extends ConsumerStatefulWidget {
  const NoticeDialog({super.key, this.notice});

  final Notice? notice;

  @override
  ConsumerState<NoticeDialog> createState() => _NoticeDialogState();
}

class _NoticeDialogState extends ConsumerState<NoticeDialog> {
  late final _title = TextEditingController(text: widget.notice?.title);
  late final _body = TextEditingController(text: widget.notice?.body);
  late DateTime _startsAt = widget.notice?.startsAt ?? DateTime.now();
  late DateTime? _endsAt = widget.notice?.endsAt;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return;
    if (_endsAt != null && !_endsAt!.isAfter(_startsAt)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('종료 시각이 시작보다 늦어야 합니다.')));
      return;
    }
    setState(() => _busy = true);
    final ok = await runWithSnack(
      context,
      () => ref
          .read(noticesRepositoryProvider)
          .save(
            id: widget.notice?.id,
            title: _title.text.trim(),
            body: _body.text.trim(),
            startsAt: _startsAt,
            endsAt: _endsAt,
          ),
      success: '저장했습니다.',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.notice == null ? '새 공지' : '공지 수정'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              decoration: const InputDecoration(labelText: '내용'),
              minLines: 4,
              maxLines: 10,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('게시 시작'),
              subtitle: Text(noticeTimeFormat.format(_startsAt)),
              onTap: () async {
                final v = await _pick(_startsAt);
                if (v != null) setState(() => _startsAt = v);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('게시 종료'),
              subtitle: Text(
                _endsAt == null ? '계속 게시' : noticeTimeFormat.format(_endsAt!),
              ),
              onTap: () async {
                final v = await _pick(_endsAt ?? _startsAt);
                if (v != null) setState(() => _endsAt = v);
              },
              trailing: _endsAt == null
                  ? null
                  : IconButton(
                      tooltip: '종료 없음',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _endsAt = null),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('저장')),
      ],
    );
  }
}
