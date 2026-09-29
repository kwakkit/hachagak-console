import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/console_theme.dart';
import 'console_panel.dart';
import 'status_pill.dart';

/// AsyncValue 를 로딩·에러·데이터로 그리는 공통 위젯.
class AsyncView<T> extends StatelessWidget {
  const AsyncView(this.value, {super.key, required this.builder, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ConsolePanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill('불러오기 실패', color: context.console.alert),
              const SizedBox(height: 12),
              SelectableText(
                '$e',
                style: ConsoleFonts.monoSmall.copyWith(
                  color: context.console.textLo,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('다시 시도'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    data: builder,
  );
}

/// 저장·삭제 등 쓰기 작업을 스낵바로 감싼다.
Future<bool> runWithSnack(
  BuildContext context,
  Future<void> Function() action, {
  required String success,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(success)));
    return true;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('실패: $e')));
    return false;
  }
}
