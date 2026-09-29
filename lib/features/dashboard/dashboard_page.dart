import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/async_view.dart';
import '../../app/console_widgets.dart';
import '../../core/env.dart';
import '../../core/supabase.dart';
import '../shell/console_shell.dart';

class DailyStat {
  DailyStat.fromRow(Map<String, dynamic> r)
    : day = DateTime.parse(r['day'] as String),
      trips = r['trips'] as int,
      alerts = r['alerts'] as int,
      realtimeTrips = r['realtime_trips'] as int,
      fallbackTrips = r['fallback_trips'] as int,
      apiCalls = r['api_calls'] as int,
      devices = r['devices'] as int;

  final DateTime day;
  final int trips;
  final int alerts;
  final int realtimeTrips;
  final int fallbackTrips;
  final int apiCalls;
  final int devices;
}

class DashboardData {
  DashboardData(this.days, this.newFeedback);

  /// 최근 14일, 최신순. 이벤트가 없는 날은 빠져 있다.
  final List<DailyStat> days;
  final int newFeedback;
}

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((
  ref,
) async {
  final since = DateTime.now().subtract(const Duration(days: 13));
  final rows = await db
      .from('daily_stats')
      .select()
      .eq('app', currentApp)
      .gte('day', DateFormat('yyyy-MM-dd').format(since))
      .order('day', ascending: false);
  final newFeedback = await db
      .from('feedback')
      .count()
      .eq('app', currentApp)
      .eq('status', 'new');
  return DashboardData(rows.map(DailyStat.fromRow).toList(), newFeedback);
});

final _dayFmt = DateFormat('MM.dd (E)', 'ko');
final _num = NumberFormat.decimalPattern('ko');

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
            _Tiles(data),
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
                          child: _Table(data.days),
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

class _Table extends StatelessWidget {
  const _Table(this.days);

  final List<DailyStat> days;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return DataTable(
      columns: const [
        DataColumn(label: Text('날짜')),
        DataColumn(label: Text('기기'), numeric: true),
        DataColumn(label: Text('여정'), numeric: true),
        DataColumn(label: Text('알림'), numeric: true),
        DataColumn(label: Text('실시간 / 폴백'), numeric: true),
        DataColumn(label: Text('API 호출'), numeric: true),
      ],
      rows: [
        for (final d in days)
          DataRow(
            cells: [
              DataCell(
                Text(
                  _dayFmt.format(d.day),
                  style: ConsoleFonts.body13.copyWith(color: c.textHi),
                ),
              ),
              DataCell(Text(_num.format(d.devices))),
              DataCell(Text(_num.format(d.trips))),
              DataCell(Text(_num.format(d.alerts))),
              DataCell(
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${d.realtimeTrips}',
                        style: TextStyle(color: c.ok),
                      ),
                      TextSpan(
                        text: ' / ',
                        style: TextStyle(color: c.textLo),
                      ),
                      TextSpan(
                        text: '${d.fallbackTrips}',
                        style: TextStyle(color: c.warn),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(Text(_num.format(d.apiCalls))),
            ],
          ),
      ],
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles(this.data);

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    final today = DateUtils.dateOnly(DateTime.now());
    final t = data.days.where((d) => d.day == today).firstOrNull;
    final ended = (t?.realtimeTrips ?? 0) + (t?.fallbackTrips ?? 0);
    final fallbackRate = ended == 0
        ? '–'
        : '${(t!.fallbackTrips * 100 / ended).round()}%';

    final tiles = [
      _Tile('여정', _num.format(t?.trips ?? 0), Icons.route_outlined),
      _Tile('기기', _num.format(t?.devices ?? 0), Icons.smartphone_outlined),
      _Tile('API 호출', _num.format(t?.apiCalls ?? 0), Icons.cloud_sync_outlined),
      _Tile('폴백 비율', fallbackRate, Icons.alt_route_outlined),
      _Tile(
        '새 제보',
        _num.format(data.newFeedback),
        Icons.inbox_outlined,
        accent: data.newFeedback > 0 ? c.alert : null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 900
            ? 5
            : box.maxWidth >= 560
            ? 3
            : 2;
        const gap = 12.0;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, this.icon, {this.accent});

  final String label;
  final String value;
  final IconData icon;

  /// 주의가 필요할 때만 색. 평소엔 무채색.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return ConsolePanel(
      borderColor: accent?.withValues(alpha: 0.5),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent ?? c.chromeDim),
              const SizedBox(width: 6),
              Text(label, style: ConsoleFonts.body13.copyWith(color: c.textLo)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: ConsoleFonts.readout.copyWith(color: accent ?? c.textHi),
          ),
        ],
      ),
    );
  }
}
