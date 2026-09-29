import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import 'notice.dart';

final noticesRepositoryProvider = Provider((ref) => NoticesRepository(db));

/// `notices` 조회·쓰기.
class NoticesRepository {
  NoticesRepository(this._db);

  final SupabaseClient _db;

  /// 시작 시각 최신순.
  Future<List<Notice>> fetchAll() async {
    final rows = await _db
        .from('notices')
        .select()
        .eq('app', currentApp)
        .order('starts_at', ascending: false);
    return rows.map(Notice.fromRow).toList();
  }

  /// [id] 가 없으면 새로 추가, 있으면 수정.
  Future<void> save({
    int? id,
    required String title,
    required String body,
    required DateTime startsAt,
    DateTime? endsAt,
  }) async {
    final row = {
      'app': currentApp,
      'title': title,
      'body': body,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt?.toUtc().toIso8601String(),
    };
    if (id == null) {
      await _db.from('notices').insert(row);
    } else {
      await _db.from('notices').update(row).eq('id', id);
    }
  }

  Future<void> delete(int id) => _db.from('notices').delete().eq('id', id);
}
