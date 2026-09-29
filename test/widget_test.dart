import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kwakkit_console/app/app.dart';

void main() {
  testWidgets('Supabase 설정이 없으면 안내 화면', (tester) async {
    await initializeDateFormatting('ko');
    await tester.pumpWidget(const ProviderScope(child: ConsoleApp()));
    expect(find.textContaining('Supabase 설정이 없습니다'), findsOneWidget);
  });
}
