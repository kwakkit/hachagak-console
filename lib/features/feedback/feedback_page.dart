import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/async_view.dart';
import '../../core/env.dart';
import '../../core/supabase.dart';
import '../shell/console_shell.dart';

enum FeedbackStatus {
  newOne('new', '새 제보'),
  checking('checking', '확인 중'),
  done('done', '완료');

  const FeedbackStatus(this.value, this.label);
  final String value;
  final String label;

  static FeedbackStatus parse(String v) =>
      values.firstWhere((s) => s.value == v, orElse: () => newOne);
}

const _categoryLabels = {'bug': '오류', 'idea': '제안', 'etc': '기타'};

class FeedbackItem {
  FeedbackItem.fromRow(Map<String, dynamic> r)
    : id = r['id'] as int,
      category = r['category'] as String,
      message = r['message'] as String,
      status = FeedbackStatus.parse(r['status'] as String),
      adminNote = r['admin_note'] as String?,
      appVersion = r['app_version'] as String?,
      os = r['os'] as String?,
      createdAt = DateTime.parse(r['created_at'] as String).toLocal();

  final int id;
  final String category;
  final String message;
  final FeedbackStatus status;
  final String? adminNote;
  final String? appVersion;
  final String? os;
  final DateTime createdAt;
}

/// null = 전체.
final feedbackFilterProvider = NotifierProvider<_Filter, FeedbackStatus?>(
  _Filter.new,
);

class _Filter extends Notifier<FeedbackStatus?> {
  @override
  FeedbackStatus? build() => FeedbackStatus.newOne;

  void set(FeedbackStatus? v) => state = v;
}

final feedbackProvider = FutureProvider.autoDispose<List<FeedbackItem>>((
  ref,
) async {
  final filter = ref.watch(feedbackFilterProvider);
  var q = db.from('feedback').select().eq('app', currentApp);
  if (filter != null) q = q.eq('status', filter.value);
  final rows = await q.order('created_at', ascending: false).limit(200);
  return rows.map(FeedbackItem.fromRow).toList();
});

final _fmt = DateFormat('MM.dd HH:mm', 'ko');

class FeedbackPage extends ConsumerWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(feedbackFilterProvider);
    return PageScaffold(
      title: '제보함',
      actions: [
        SegmentedButton<FeedbackStatus?>(
          segments: [
            for (final s in FeedbackStatus.values)
              ButtonSegment(value: s, label: Text(s.label)),
            const ButtonSegment(value: null, label: Text('전체')),
          ],
          selected: {filter},
          onSelectionChanged: (s) =>
              ref.read(feedbackFilterProvider.notifier).set(s.first),
        ),
      ],
      child: AsyncView(
        ref.watch(feedbackProvider),
        onRetry: () => ref.invalidate(feedbackProvider),
        builder: (items) => items.isEmpty
            ? const Center(child: Text('제보가 없습니다.'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) => _FeedbackCard(
                  item: items[i],
                  onChanged: () => ref.invalidate(feedbackProvider),
                ),
              ),
      ),
    );
  }
}

class _FeedbackCard extends StatefulWidget {
  const _FeedbackCard({required this.item, required this.onChanged});

  final FeedbackItem item;
  final VoidCallback onChanged;

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
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
      () => db
          .from('feedback')
          .update({
            'status': _status.value,
            'admin_note': _note.text.trim().isEmpty ? null : _note.text.trim(),
          })
          .eq('id', widget.item.id),
      success: '저장했습니다.',
    );
    if (ok) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final texts = Theme.of(context).textTheme;
    final meta = [
      _categoryLabels[item.category] ?? item.category,
      _fmt.format(item.createdAt),
      if (item.appVersion != null) 'v${item.appVersion}',
      if (item.os != null) item.os!,
    ].join(' · ');

    return Card(
      child: ExpansionTile(
        title: Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(meta, style: texts.bodySmall),
        trailing: Chip(label: Text(item.status.label)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(item.message),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: '관리자 메모'),
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<FeedbackStatus>(
                value: _status,
                items: [
                  for (final s in FeedbackStatus.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (s) => setState(() => _status = s!),
              ),
              FilledButton.tonal(onPressed: _save, child: const Text('저장')),
            ],
          ),
        ],
      ),
    );
  }
}
