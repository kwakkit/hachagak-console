import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import 'feedback_item.dart';
import 'feedback_status.dart';

final feedbackRepositoryProvider = Provider((ref) => FeedbackRepository(db));

/// `feedback` 조회·처리. 제보 추가는 하차각(anon)만 한다.
class FeedbackRepository {
  FeedbackRepository(this._db);

  final SupabaseClient _db;

  /// 최신순 최대 200건. [status] 가 null 이면 전체.
  Future<List<FeedbackItem>> fetch({FeedbackStatus? status}) async {
    var q = _db.from('feedback').select().eq('app', currentApp);
    if (status != null) q = q.eq('status', status.value);
    final rows = await q.order('created_at', ascending: false).limit(200);
    return rows.map(FeedbackItem.fromRow).toList();
  }

  Future<int> countNew() => _db
      .from('feedback')
      .count()
      .eq('app', currentApp)
      .eq('status', FeedbackStatus.newOne.value);

  /// 빈 메모는 null 로 저장.
  Future<void> update(int id, FeedbackStatus status, String adminNote) => _db
      .from('feedback')
      .update({
        'status': status.value,
        'admin_note': adminNote.trim().isEmpty ? null : adminNote.trim(),
      })
      .eq('id', id);
}
