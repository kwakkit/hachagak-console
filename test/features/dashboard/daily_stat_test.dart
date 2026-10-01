import 'package:flutter_test/flutter_test.dart';
import 'package:hachagak_console/features/dashboard/daily_stat.dart';

void main() {
  final base = <String, dynamic>{
    'day': '2026-09-30',
    'trips': 5,
    'alerts': 9,
    'realtime_trips': 2,
    'fallback_trips': 1,
    'api_calls': 40,
    'devices': 3,
  };

  test('0002 열(시간표·종료·도착)을 읽는다', () {
    final s = DailyStat.fromRow({
      ...base,
      'timetable_trips': 1,
      'ended_trips': 4,
      'arrived_trips': 3,
    });
    expect(s.day, DateTime(2026, 9, 30));
    expect(s.timetableTrips, 1);
    expect(s.endedTrips, 4);
    expect(s.arrivedTrips, 3);
  });

  test('마이그레이션 전 뷰(0001)여도 깨지지 않고 0 으로', () {
    final s = DailyStat.fromRow(base);
    expect(s.trips, 5);
    expect(s.timetableTrips, 0);
    expect(s.endedTrips, 0);
    expect(s.arrivedTrips, 0);
  });
}
