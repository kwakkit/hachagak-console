import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/async_view.dart';
import '../../core/env.dart';
import '../../core/supabase.dart';
import '../shell/console_shell.dart';

class Notice {
  Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.startsAt,
    this.endsAt,
  });

  factory Notice.fromRow(Map<String, dynamic> r) => Notice(
    id: r['id'] as int,
    title: r['title'] as String,
    body: r['body'] as String,
    startsAt: DateTime.parse(r['starts_at'] as String).toLocal(),
    endsAt: r['ends_at'] == null
        ? null
        : DateTime.parse(r['ends_at'] as String).toLocal(),
  );

  final int id;
  final String title;
  final String body;
  final DateTime startsAt;
  final DateTime? endsAt;

  bool get isLive {
    final now = DateTime.now();
    return !startsAt.isAfter(now) && (endsAt == null || endsAt!.isAfter(now));
  }
}

final noticesProvider = FutureProvider.autoDispose<List<Notice>>((ref) async {
  final rows = await db
      .from('notices')
      .select()
      .eq('app', currentApp)
      .order('starts_at', ascending: false);
  return rows.map(Notice.fromRow).toList();
});

final _fmt = DateFormat('yyyy.MM.dd HH:mm', 'ko');

class NoticesPage extends ConsumerWidget {
  const NoticesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> edit([Notice? n]) async {
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) => _NoticeDialog(notice: n),
      );
      if (saved == true) ref.invalidate(noticesProvider);
    }

    return PageScaffold(
      title: '공지',
      actions: [
        FilledButton.icon(
          onPressed: edit,
          icon: const Icon(Icons.add),
          label: const Text('새 공지'),
        ),
      ],
      child: AsyncView(
        ref.watch(noticesProvider),
        onRetry: () => ref.invalidate(noticesProvider),
        builder: (list) => list.isEmpty
            ? const Center(child: Text('공지가 없습니다.'))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = list[i];
                  final period =
                      '${_fmt.format(n.startsAt)} ~ ${n.endsAt == null ? '계속' : _fmt.format(n.endsAt!)}';
                  return ListTile(
                    title: Text(n.title),
                    subtitle: Text(period),
                    leading: Icon(
                      n.isLive ? Icons.circle : Icons.circle_outlined,
                      size: 12,
                      color: n.isLive ? Colors.green : null,
                    ),
                    trailing: IconButton(
                      tooltip: '삭제',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await _confirmDelete(context, n.title);
                        if (!ok || !context.mounted) return;
                        await runWithSnack(
                          context,
                          () => db.from('notices').delete().eq('id', n.id),
                          success: '삭제했습니다.',
                        );
                        ref.invalidate(noticesProvider);
                      },
                    ),
                    onTap: () => edit(n),
                  );
                },
              ),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('공지 삭제'),
        content: Text('"$title" 공지를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    ) ??
    false;

class _NoticeDialog extends StatefulWidget {
  const _NoticeDialog({this.notice});

  final Notice? notice;

  @override
  State<_NoticeDialog> createState() => _NoticeDialogState();
}

class _NoticeDialogState extends State<_NoticeDialog> {
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
    final row = {
      'app': currentApp,
      'title': _title.text.trim(),
      'body': _body.text.trim(),
      'starts_at': _startsAt.toUtc().toIso8601String(),
      'ends_at': _endsAt?.toUtc().toIso8601String(),
    };
    final id = widget.notice?.id;
    final ok = await runWithSnack(
      context,
      () => id == null
          ? db.from('notices').insert(row)
          : db.from('notices').update(row).eq('id', id),
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
              subtitle: Text(_fmt.format(_startsAt)),
              onTap: () async {
                final v = await _pick(_startsAt);
                if (v != null) setState(() => _startsAt = v);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('게시 종료'),
              subtitle: Text(_endsAt == null ? '계속 게시' : _fmt.format(_endsAt!)),
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
