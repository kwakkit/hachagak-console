import 'subway_line.dart';

/// 기간 동안 한 노선을 이용한 여정 수 (`daily_line_stats` 를 노선별로 합친 값).
class LineUsage {
  const LineUsage(this.line, this.trips);

  final SubwayLine line;
  final int trips;

  /// `daily_line_stats` 행들(`line`, `trips`)을 노선별로 합쳐 많은 순으로.
  static List<LineUsage> aggregate(Iterable<Map<String, dynamic>> rows) {
    final sums = <String, int>{};
    for (final r in rows) {
      final id = r['line'] as String;
      sums[id] = (sums[id] ?? 0) + (r['trips'] as int);
    }
    final out = [
      for (final e in sums.entries) LineUsage(SubwayLine.of(e.key), e.value),
    ]..sort((a, b) => b.trips.compareTo(a.trips));
    return out;
  }
}
