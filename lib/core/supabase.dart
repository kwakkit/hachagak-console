import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get db => Supabase.instance.client;

/// 로그인 세션 변화.
final sessionProvider = StreamProvider<Session?>((ref) async* {
  yield db.auth.currentSession;
  await for (final state in db.auth.onAuthStateChange) {
    yield state.session;
  }
});

/// 로그인한 계정이 admins 테이블에 있는지.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final session = ref.watch(sessionProvider).value;
  if (session == null) return false;
  final row = await db
      .from('admins')
      .select('user_id')
      .eq('user_id', session.user.id)
      .maybeSingle();
  return row != null;
});
