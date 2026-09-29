import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/console_widgets.dart';
import '../feedback/feedback_repository.dart';
import 'dashboard_data.dart';
import 'dashboard_page/dashboard_table.dart';
import 'dashboard_page/today_tiles.dart';
import 'dashboard_repository.dart';

export 'daily_stat.dart';
export 'dashboard_data.dart';
export 'dashboard_repository.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((
  ref,
) async {
  final (days, newFeedback) = await (
    ref.watch(dashboardRepositoryProvider).fetchDailyStats(),
    ref.watch(feedbackRepositoryProvider).countNew(),
  ).wait;
  return DashboardData(days, newFeedback);
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: '대시보드',
      eyebrow: 'Overview · 하차각',
      actions: [
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(dashboardProvider),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('새로고침'),
        ),
      ],
      child: AsyncView(
        ref.watch(dashboardProvider),
        onRetry: () => ref.invalidate(dashboardProvider),
        builder: (data) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const ConsoleEyebrow('Today · 오늘'),
            const SizedBox(height: 10),
            TodayTiles(data),
            const SizedBox(height: 28),
            const ConsoleEyebrow('Last 14 days · 최근 14일'),
            const SizedBox(height: 10),
            ConsolePanel(
              padding: EdgeInsets.zero,
              child: data.days.isEmpty
                  ? const EmptyState(
                      icon: Icons.sensors_off_outlined,
                      message: '아직 수집된 이벤트가 없습니다.\n하차각 이벤트 전송(3주차) 후 채워집니다.',
                    )
                  : LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: box.maxWidth),
                          child: DashboardTable(data.days),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
