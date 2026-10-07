import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import 'daily_stat.dart';
import 'line_usage.dart';

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository(db));

/// `daily_stats`·`daily_line_stats` 집계 테이블 조회. 새 제보 수는 `FeedbackRepository.countNew`.
class DashboardRepository {
  DashboardRepository(this._db);

  final SupabaseClient _db;

  /// 오늘 포함 최근 [days] 일, 최신순. 이벤트가 없는 날은 빠진다.
  ///
  /// 집계는 pg_cron 이 매시 갱신하지만, 방금 들어온 이벤트도 보이게 조회 직전에
  /// 바뀐 날만 다시 센다(`refresh_daily_stats`, 0003). 갱신이 실패해도
  /// (0003 적용 전 DB 등) 마지막 집계를 그대로 보여 준다.
  Future<List<DailyStat>> fetchDailyStats({int days = 14}) async {
    try {
      await _db.rpc<void>('refresh_daily_stats');
    } on PostgrestException {
      // 무시 — 아래 조회는 이전 집계로도 동작한다.
    }
    final since = DateTime.now().subtract(Duration(days: days - 1));
    final rows = await _db
        .from('daily_stats')
        .select()
        .eq('app', currentApp)
        .gte('day', DateFormat('yyyy-MM-dd').format(since))
        .order('day', ascending: false);
    return rows.map(DailyStat.fromRow).toList();
  }

  /// 최근 [days] 일 노선별 이용 여정 수, 많은 순. [fetchDailyStats] 가 먼저
  /// 갱신해 두므로 여기선 조회만. 0004 적용 전 DB(표 없음)면 빈 목록.
  Future<List<LineUsage>> fetchLineUsage({int days = 14}) async {
    final since = DateTime.now().subtract(Duration(days: days - 1));
    try {
      final rows = await _db
          .from('daily_line_stats')
          .select('line, trips')
          .eq('app', currentApp)
          .gte('day', DateFormat('yyyy-MM-dd').format(since));
      return LineUsage.aggregate(rows);
    } on PostgrestException {
      return const [];
    }
  }
}
