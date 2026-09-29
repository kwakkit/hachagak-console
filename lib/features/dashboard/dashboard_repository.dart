import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import 'daily_stat.dart';

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository(db));

/// `daily_stats` 뷰 조회. 새 제보 수는 `FeedbackRepository.countNew`.
class DashboardRepository {
  DashboardRepository(this._db);

  final SupabaseClient _db;

  /// 오늘 포함 최근 [days] 일, 최신순. 이벤트가 없는 날은 빠진다.
  Future<List<DailyStat>> fetchDailyStats({int days = 14}) async {
    final since = DateTime.now().subtract(Duration(days: days - 1));
    final rows = await _db
        .from('daily_stats')
        .select()
        .eq('app', currentApp)
        .gte('day', DateFormat('yyyy-MM-dd').format(since))
        .order('day', ascending: false);
    return rows.map(DailyStat.fromRow).toList();
  }
}
