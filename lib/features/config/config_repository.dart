import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import 'config_entry.dart';

final configRepositoryProvider = Provider((ref) => ConfigRepository(db));

/// `app_config` 조회·수정. 키 추가·삭제는 마이그레이션으로만.
class ConfigRepository {
  ConfigRepository(this._db);

  final SupabaseClient _db;

  /// 키 이름순.
  Future<List<ConfigEntry>> fetchAll() async {
    final rows = await _db
        .from('app_config')
        .select()
        .eq('app', currentApp)
        .order('key');
    return rows.map(ConfigEntry.fromRow).toList();
  }

  Future<void> update(String key, Object value) => _db
      .from('app_config')
      .update({'value': value})
      .eq('app', currentApp)
      .eq('key', key);
}
