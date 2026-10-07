import 'package:flutter/material.dart';

import '../../../app/console_widgets.dart';
import '../daily_stat.dart';
import 'dashboard_formats.dart';

/// 최근 14일 일별 표 — 끝난 여정의 추적 모드(실시간/폴백/시간표)는 색으로 구분.
class DashboardTable extends StatelessWidget {
  const DashboardTable(this.days, {super.key});

  final List<DailyStat> days;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    // 좁은 창에선 열 간격을 줄여 가로 스크롤을 덜 하게.
    final narrow = MediaQuery.sizeOf(context).width < wideBreakpoint;
    return DataTable(
      columnSpacing: narrow ? 24 : 56,
      horizontalMargin: narrow ? 16 : 24,
      columns: const [
        DataColumn(label: Text('날짜')),
        DataColumn(label: Text('기기'), numeric: true),
        DataColumn(label: Text('여정'), numeric: true),
        DataColumn(label: Text('알림'), numeric: true),
        DataColumn(label: Text('실시간 / 폴백 / 시간표'), numeric: true),
        DataColumn(label: Text('도착 / 종료'), numeric: true),
        DataColumn(label: Text('평균 정거장 / 환승 여정'), numeric: true),
        DataColumn(label: Text('API 호출'), numeric: true),
      ],
      rows: [
        for (final d in days)
          DataRow(
            cells: [
              DataCell(
                Text(
                  dashboardDayFormat.format(d.day),
                  style: ConsoleFonts.body13.copyWith(color: c.textHi),
                ),
              ),
              DataCell(Text(dashboardNumberFormat.format(d.devices))),
              DataCell(Text(dashboardNumberFormat.format(d.trips))),
              DataCell(Text(dashboardNumberFormat.format(d.alerts))),
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
                      TextSpan(
                        text: ' / ',
                        style: TextStyle(color: c.textLo),
                      ),
                      TextSpan(
                        text: '${d.timetableTrips}',
                        style: TextStyle(color: c.textLo),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${dashboardNumberFormat.format(d.arrivedTrips)} / '
                  '${dashboardNumberFormat.format(d.endedTrips)}',
                ),
              ),
              DataCell(
                Text(
                  d.routeTrips == 0
                      ? '–'
                      : '${(d.stopsSum / d.routeTrips).toStringAsFixed(1)} / '
                            '${dashboardNumberFormat.format(d.transferTrips)}',
                ),
              ),
              DataCell(Text(dashboardNumberFormat.format(d.apiCalls))),
            ],
          ),
      ],
    );
  }
}
