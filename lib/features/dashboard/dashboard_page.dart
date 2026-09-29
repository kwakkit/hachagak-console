import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/async_view.dart';
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
      actions: [
        IconButton(
          tooltip: '새로고침',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(dashboardProvider),
        ),
      ],
      child: AsyncView(
        ref.watch(dashboardProvider),
        onRetry: () => ref.invalidate(dashboardProvider),
        builder: (data) => ListView(
          children: [
            _Tiles(data),
            const SizedBox(height: 24),
            Text('최근 14일', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (data.days.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('아직 수집된 이벤트가 없습니다. 하차각 연동 후 채워집니다.'),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('날짜')),
                    DataColumn(label: Text('기기'), numeric: true),
                    DataColumn(label: Text('여정'), numeric: true),
                    DataColumn(label: Text('알림'), numeric: true),
                    DataColumn(label: Text('실시간 / 폴백'), numeric: true),
                    DataColumn(label: Text('API 호출'), numeric: true),
                  ],
                  rows: [
                    for (final d in data.days)
                      DataRow(
                        cells: [
                          DataCell(Text(_dayFmt.format(d.day))),
                          DataCell(Text(_num.format(d.devices))),
                          DataCell(Text(_num.format(d.trips))),
                          DataCell(Text(_num.format(d.alerts))),
                          DataCell(
                            Text('${d.realtimeTrips} / ${d.fallbackTrips}'),
                          ),
                          DataCell(Text(_num.format(d.apiCalls))),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles(this.data);

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final t = data.days.where((d) => d.day == today).firstOrNull;
    final ended = (t?.realtimeTrips ?? 0) + (t?.fallbackTrips ?? 0);
    final fallbackRate = ended == 0
        ? '-'
        : '${(t!.fallbackTrips * 100 / ended).round()}%';

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Tile('오늘 여정', _num.format(t?.trips ?? 0)),
        _Tile('오늘 기기', _num.format(t?.devices ?? 0)),
        _Tile('오늘 API 호출', _num.format(t?.apiCalls ?? 0)),
        _Tile('폴백 비율', fallbackRate),
        _Tile('새 제보', _num.format(data.newFeedback)),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final texts = Theme.of(context).textTheme;
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: texts.labelMedium),
              const SizedBox(height: 8),
              Text(value, style: texts.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
