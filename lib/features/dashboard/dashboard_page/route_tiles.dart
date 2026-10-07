import 'package:flutter/material.dart';

import '../daily_stat.dart';
import 'dashboard_formats.dart';
import 'stat_tile.dart';

/// [days] 동안 노선 정보가 담긴 여정 수 — 경로 평균·노선 비율의 분모.
int routeTripsOf(List<DailyStat> days) =>
    days.fold(0, (sum, d) => sum + d.routeTrips);

/// 기간 경로 요약 4개 — 경로 정보 여정·평균 정거장·환승 여정 비율·평균 환승.
/// 역 이름은 수집하지 않으므로(Play 데이터 보안 양식 범위) 노선·횟수 단위까지만.
class RouteTiles extends StatelessWidget {
  const RouteTiles(this.days, {super.key});

  final List<DailyStat> days;

  @override
  Widget build(BuildContext context) {
    final n = routeTripsOf(days);
    int sum(int Function(DailyStat) f) => days.fold(0, (s, d) => s + f(d));
    String avg(int total) => n == 0 ? '–' : (total / n).toStringAsFixed(1);

    final tiles = [
      StatTile(
        '경로 정보 여정',
        dashboardNumberFormat.format(n),
        Icons.alt_route_outlined,
      ),
      StatTile(
        '평균 정거장',
        avg(sum((d) => d.stopsSum)),
        Icons.linear_scale_outlined,
      ),
      StatTile(
        '환승 여정 비율',
        n == 0 ? '–' : '${(sum((d) => d.transferTrips) * 100 / n).round()}%',
        Icons.transfer_within_a_station_outlined,
      ),
      StatTile(
        '평균 환승',
        avg(sum((d) => d.transfersSum)),
        Icons.sync_alt_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 720 ? 4 : 2;
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
