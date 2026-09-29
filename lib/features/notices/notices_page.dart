import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/console_widgets.dart';
import 'notice.dart';
import 'notices_page/notice_dialog.dart';
import 'notices_page/notice_row.dart';
import 'notices_repository.dart';

export 'notice.dart';
export 'notices_repository.dart';

final noticesProvider = FutureProvider.autoDispose<List<Notice>>(
  (ref) => ref.watch(noticesRepositoryProvider).fetchAll(),
);

class NoticesPage extends ConsumerWidget {
  const NoticesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> edit([Notice? n]) async {
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) => NoticeDialog(notice: n),
      );
      if (saved == true) ref.invalidate(noticesProvider);
    }

    return PageScaffold(
      title: '공지',
      eyebrow: 'Notices · 앱 홈 배너',
      actions: [
        FilledButton.icon(
          onPressed: edit,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('새 공지'),
        ),
      ],
      child: AsyncView(
        ref.watch(noticesProvider),
        onRetry: () => ref.invalidate(noticesProvider),
        builder: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.campaign_outlined,
                message: '공지가 없습니다.\n게시 중인 공지는 하차각 홈 상단에 배너로 뜹니다.',
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => NoticeRow(
                  notice: list[i],
                  onEdit: () => edit(list[i]),
                  onDelete: () async {
                    final n = list[i];
                    final ok = await _confirmDelete(context, n.title);
                    if (!ok || !context.mounted) return;
                    await runWithSnack(
                      context,
                      () => ref.read(noticesRepositoryProvider).delete(n.id),
                      success: '삭제했습니다.',
                    );
                    ref.invalidate(noticesProvider);
                  },
                ),
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
            style: FilledButton.styleFrom(backgroundColor: c.console.alert),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    ) ??
    false;
