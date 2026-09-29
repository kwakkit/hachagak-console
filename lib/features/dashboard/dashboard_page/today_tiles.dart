import 'package:flutter/material.dart';

import '../../../app/console_widgets.dart';
import '../dashboard_data.dart';
import 'dashboard_formats.dart';
import 'stat_tile.dart';

/// 오늘 수치 패널 5개 — 폭에 따라 5/3/2열.
class TodayTiles extends StatelessWidget {
  const TodayTiles(this.data, {super.key});

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
      StatTile(
        '여정',
        dashboardNumberFormat.format(t?.trips ?? 0),
        Icons.route_outlined,
      ),
      StatTile(
        '기기',
        dashboardNumberFormat.format(t?.devices ?? 0),
        Icons.smartphone_outlined,
      ),
      StatTile(
        'API 호출',
        dashboardNumberFormat.format(t?.apiCalls ?? 0),
        Icons.cloud_sync_outlined,
      ),
      StatTile('폴백 비율', fallbackRate, Icons.alt_route_outlined),
      StatTile(
        '새 제보',
        dashboardNumberFormat.format(data.newFeedback),
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
