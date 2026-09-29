import 'daily_stat.dart';

/// 대시보드 한 화면분 — 최근 14일 집계 + 새 제보 수.
class DashboardData {
  DashboardData(this.days, this.newFeedback);

  /// 최근 14일, 최신순. 이벤트가 없는 날은 빠져 있다.
  final List<DailyStat> days;
  final int newFeedback;
}
