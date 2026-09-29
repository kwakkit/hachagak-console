/// `daily_stats` 뷰 한 행 — Asia/Seoul 기준 하루 집계.
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
