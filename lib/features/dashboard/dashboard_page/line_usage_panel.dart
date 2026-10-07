import 'package:flutter/material.dart';

import '../../../app/console_widgets.dart';
import '../line_usage.dart';
import 'line_usage_row.dart';

/// 노선별 이용 — 노선마다 막대 하나. 한 여정이 여러 노선을 타므로 비율의 합은
/// 100% 를 넘을 수 있다(비율 = 그 노선을 탄 여정 / 경로 정보 여정).
class LineUsagePanel extends StatelessWidget {
  const LineUsagePanel(this.lines, {super.key, required this.routeTrips});

  final List<LineUsage> lines;
  final int routeTrips;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const ConsolePanel(
        padding: EdgeInsets.zero,
        child: EmptyState(
          icon: Icons.subway_outlined,
          message: '아직 노선 정보가 담긴 여정이 없습니다.\n하차각 새 버전(노선 통계)부터 채워집니다.',
        ),
      );
    }
    final max = lines.first.trips;
    return ConsolePanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '노선별 이용 여정',
            style: ConsoleFonts.label.copyWith(color: context.console.textLo),
          ),
          const SizedBox(height: 12),
          for (final u in lines)
            LineUsageRow(u, maxTrips: max, routeTrips: routeTrips),
        ],
      ),
    );
  }
}
