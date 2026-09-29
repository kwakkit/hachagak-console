import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/console_widgets.dart';
import 'config_entry.dart';
import 'config_page/entry_layout.dart';
import 'config_page/text_entry.dart';
import 'config_repository.dart';

export 'config_entry.dart';
export 'config_repository.dart';

final configProvider = FutureProvider.autoDispose<List<ConfigEntry>>(
  (ref) => ref.watch(configRepositoryProvider).fetchAll(),
);

final _semver = RegExp(r'^\d+\.\d+\.\d+$');

class ConfigPage extends ConsumerWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> save(String key, Object value) async {
      await runWithSnack(
        context,
        () => ref.read(configRepositoryProvider).update(key, value),
        success: '$key 저장됨',
      );
      ref.invalidate(configProvider);
    }

    return PageScaffold(
      title: '원격 설정',
      eyebrow: 'Remote config · 다음 앱 실행부터 적용',
      child: AsyncView(
        ref.watch(configProvider),
        onRetry: () => ref.invalidate(configProvider),
        builder: (entries) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 32),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final e = entries[i];
            return ConsolePanel(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: switch (e.value) {
                final bool v => EntryLayout(
                  entry: e,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusPill(
                        v ? 'ON' : 'OFF',
                        color: v ? context.console.ok : context.console.alert,
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: v,
                        onChanged: (next) async {
                          if (!next || await _confirmOn(context, e.key)) {
                            await save(e.key, next);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                final String v when e.key.endsWith('_version') => TextEntry(
                  entry: e,
                  initial: v,
                  validator: (s) => _semver.hasMatch(s) ? null : '형식: 0.3.0',
                  onSave: (s) => save(e.key, s),
                ),
                final v => TextEntry(
                  entry: e,
                  initial: jsonEncode(v),
                  validator: (s) {
                    try {
                      jsonDecode(s);
                      return null;
                    } catch (_) {
                      return 'JSON 형식이 아닙니다';
                    }
                  },
                  onSave: (s) => save(e.key, jsonDecode(s) as Object),
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

/// 켜는 쪽은 즉시 전체 사용자에게 영향이 가므로 한 번 더 묻는다.
Future<bool> _confirmOn(BuildContext context, String key) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('$key 켜기'),
        content: const Text('다음 앱 실행부터 모든 사용자에게 적용됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('켜기'),
          ),
        ],
      ),
    ) ??
    false;
