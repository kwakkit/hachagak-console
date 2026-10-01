/// `daily_stats` 뷰 한 행 — Asia/Seoul 기준 하루 집계.
class DailyStat {
  DailyStat.fromRow(Map<String, dynamic> r)
    : day = DateTime.parse(r['day'] as String),
      trips = r['trips'] as int,
      alerts = r['alerts'] as int,
      realtimeTrips = r['realtime_trips'] as int,
      fallbackTrips = r['fallback_trips'] as int,
      apiCalls = r['api_calls'] as int,
      devices = r['devices'] as int,
      // 0002 에서 추가된 열 — 마이그레이션 전 DB 에서도 깨지지 않게 0 으로.
      timetableTrips = (r['timetable_trips'] as int?) ?? 0,
      endedTrips = (r['ended_trips'] as int?) ?? 0,
      arrivedTrips = (r['arrived_trips'] as int?) ?? 0;

  final DateTime day;

  /// 사용자가 시작한 여정 수 (`trip_started`).
  final int trips;
  final int alerts;

  /// 끝난 여정의 추적 모드별 수 (`trip_ended.mode`).
  final int realtimeTrips;
  final int fallbackTrips;
  final int timetableTrips;
  final int apiCalls;
  final int devices;

  /// 끝난 여정 수와 그중 목적지 도착으로 끝난 수 (`trip_ended.reason`).
  final int endedTrips;
  final int arrivedTrips;
}
