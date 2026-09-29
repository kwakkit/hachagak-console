import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/console_widgets.dart';
import 'feedback_filter.dart';
import 'feedback_item.dart';
import 'feedback_page/feedback_card.dart';
import 'feedback_repository.dart';
import 'feedback_status.dart';

export 'feedback_filter.dart';
export 'feedback_item.dart';
export 'feedback_repository.dart';
export 'feedback_status.dart';

final feedbackProvider = FutureProvider.autoDispose<List<FeedbackItem>>(
  (ref) => ref
      .watch(feedbackRepositoryProvider)
      .fetch(status: ref.watch(feedbackFilterProvider)),
);

class FeedbackPage extends ConsumerWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(feedbackFilterProvider);
    return PageScaffold(
      title: '제보함',
      eyebrow: 'Inbox · 앱 문의·오류 제보',
      actions: [
        SegmentedButton<FeedbackStatus?>(
          segments: [
            for (final s in FeedbackStatus.values)
              ButtonSegment(value: s, label: Text(s.label)),
            const ButtonSegment(value: null, label: Text('전체')),
          ],
          selected: {filter},
          showSelectedIcon: false,
          onSelectionChanged: (s) =>
              ref.read(feedbackFilterProvider.notifier).set(s.first),
        ),
      ],
      child: AsyncView(
        ref.watch(feedbackProvider),
        onRetry: () => ref.invalidate(feedbackProvider),
        builder: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.inbox_outlined,
                message: '제보가 없습니다.\n하차각 설정 → "문의·오류 제보" 로 들어옵니다.',
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => FeedbackCard(
                  item: items[i],
                  onChanged: () => ref.invalidate(feedbackProvider),
                ),
              ),
      ),
    );
  }
}
