import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hachagak_console/app/console_widgets.dart';
import 'package:hachagak_console/features/dashboard/daily_stat.dart';
import 'package:hachagak_console/features/dashboard/dashboard_page/line_usage_panel.dart';
import 'package:hachagak_console/features/dashboard/dashboard_page/route_tiles.dart';
import 'package:hachagak_console/features/dashboard/line_usage.dart';
import 'package:hachagak_console/features/dashboard/subway_line.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  test('일별 노선 행을 노선별로 합쳐 많은 순으로', () {
    final out = LineUsage.aggregate([
      {'line': '3', 'trips': 2},
      {'line': '2', 'trips': 3},
      {'line': '3', 'trips': 4},
      {'line': 'GTXA', 'trips': 1},
    ]);
    expect([for (final u in out) u.line.name], ['3호선', '2호선', 'GTX-A']);
    expect([for (final u in out) u.trips], [6, 3, 1]);
  });

  test('모르는 노선 id 는 id 그대로 표시', () {
    final l = SubwayLine.of('B1');
    expect(l.name, 'B1');
  });

  DailyStat day(int routeTrips, int transferTrips, int transfers, int stops) =>
      DailyStat.fromRow({
        'day': '2026-10-07',
        'trips': routeTrips,
        'alerts': 0,
        'realtime_trips': 0,
        'fallback_trips': 0,
        'api_calls': 0,
        'devices': 1,
        'route_trips': routeTrips,
        'transfer_trips': transferTrips,
        'transfers_sum': transfers,
        'stops_sum': stops,
      });

  Widget host(Widget child) => MaterialApp(
    theme: consoleTheme(Brightness.light),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  testWidgets('경로 요약 — 기간 합으로 평균·비율', (tester) async {
    await tester.pumpWidget(
      host(RouteTiles([day(3, 2, 3, 26), day(1, 0, 0, 4)])),
    );
    expect(find.text('4'), findsOneWidget); // 경로 정보 여정
    expect(find.text('7.5'), findsOneWidget); // (26+4)/4
    expect(find.text('50%'), findsOneWidget); // 2/4
    expect(find.text('0.8'), findsOneWidget); // 3/4
  });

  testWidgets('노선별 이용 — 이름·여정 수·비율, 없으면 안내', (tester) async {
    await tester.pumpWidget(
      host(
        LineUsagePanel([
          LineUsage(SubwayLine.of('2'), 3),
          LineUsage(SubwayLine.of('3'), 2),
        ], routeTrips: 4),
      ),
    );
    expect(find.text('2호선'), findsOneWidget);
    expect(find.text('3 · 75%'), findsOneWidget);
    expect(find.text('2 · 50%'), findsOneWidget);

    await tester.pumpWidget(host(const LineUsagePanel([], routeTrips: 0)));
    expect(find.textContaining('노선 정보가 담긴 여정이 없습니다'), findsOneWidget);
  });
}
