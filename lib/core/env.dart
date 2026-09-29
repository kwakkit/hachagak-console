/// 빌드 시 `--dart-define-from-file=dart_defines/local.json` 으로 주입.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      !supabaseUrl.contains('YOUR_PROJECT') &&
      supabasePublishableKey.isNotEmpty &&
      !supabasePublishableKey.startsWith('PUT_');
}

/// 콘솔이 관리하는 앱. 지금은 하차각 하나 (`app` 컬럼으로 앱 추가 여지만 남겨 둠).
const currentApp = 'hachagak';
