import 'daily_stat.dart';
import 'line_usage.dart';

/// 대시보드 한 화면분 — 최근 14일 집계·노선별 이용 + 새 제보 수.
class DashboardData {
  DashboardData(this.days, this.newFeedback, {this.lines = const []});

  /// 최근 14일, 최신순. 이벤트가 없는 날은 빠져 있다.
  final List<DailyStat> days;
  final int newFeedback;

  /// 최근 14일 노선별 이용 여정 수, 많은 순.
  final List<LineUsage> lines;
}
