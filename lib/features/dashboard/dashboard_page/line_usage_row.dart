import 'package:flutter/material.dart';

import '../../../app/console_widgets.dart';
import '../line_usage.dart';
import 'dashboard_formats.dart';

/// 노선 한 줄 — 상징색 점·이름 · 가장 많은 노선 대비 막대 · 여정 수(비율).
class LineUsageRow extends StatelessWidget {
  const LineUsageRow(
    this.usage, {
    super.key,
    required this.maxTrips,
    required this.routeTrips,
  });

  final LineUsage usage;
  final int maxTrips;
  final int routeTrips;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    final share = routeTrips == 0
        ? ''
        : ' · ${(usage.trips * 100 / routeTrips).round()}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          ConsoleDot(color: usage.line.color, glow: false),
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            child: Text(
              usage.line.name,
              overflow: TextOverflow.ellipsis,
              style: ConsoleFonts.body13.copyWith(color: c.textHi),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Container(
                height: 8,
                color: c.hairline,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: maxTrips == 0 ? 0 : usage.trips / maxTrips,
                  child: Container(color: usage.line.color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Text(
              '${dashboardNumberFormat.format(usage.trips)}$share',
              textAlign: TextAlign.right,
              style: ConsoleFonts.monoSmall.copyWith(color: c.textLo),
            ),
          ),
        ],
      ),
    );
  }
}
