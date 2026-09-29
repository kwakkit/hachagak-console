import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/async_view.dart';
import '../../app/console_widgets.dart';
import '../../core/env.dart';
import '../../core/supabase.dart';
import '../shell/console_shell.dart';

class ConfigEntry {
  ConfigEntry(this.key, this.value, this.description);

  factory ConfigEntry.fromRow(Map<String, dynamic> r) =>
      ConfigEntry(r['key'] as String, r['value'], r['description'] as String?);

  final String key;
  final Object? value;
  final String? description;
}

final configProvider = FutureProvider.autoDispose<List<ConfigEntry>>((
  ref,
) async {
  final rows = await db
      .from('app_config')
      .select()
      .eq('app', currentApp)
      .order('key');
  return rows.map(ConfigEntry.fromRow).toList();
});

final _semver = RegExp(r'^\d+\.\d+\.\d+$');

/// 알려진 키의 사람용 이름. 모르는 키는 키 그대로.
const _titles = {
  'min_version': '최소 지원 버전',
  'latest_version': '최신 버전',
  'realtime_enabled': '실시간 열차 매칭 (방법 A)',
};

class ConfigPage extends ConsumerWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> save(String key, Object value) async {
      await runWithSnack(
        context,
        () => db
            .from('app_config')
            .update({'value': value})
            .eq('app', currentApp)
            .eq('key', key),
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
                final bool v => _EntryLayout(
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
                final String v when e.key.endsWith('_version') => _TextEntry(
                  entry: e,
                  initial: v,
                  validator: (s) => _semver.hasMatch(s) ? null : '형식: 0.3.0',
                  onSave: (s) => save(e.key, s),
                ),
                final v => _TextEntry(
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

/// 왼쪽: 이름 + mono 키 + 설명, 오른쪽: 컨트롤. 좁으면 아래로 내린다.
class _EntryLayout extends StatelessWidget {
  const _EntryLayout({required this.entry, required this.trailing});

  final ConfigEntry entry;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _titles[entry.key] ?? entry.key,
          style: ConsoleFonts.label.copyWith(color: c.textHi),
        ),
        const SizedBox(height: 4),
        Text(
          entry.key,
          style: ConsoleFonts.monoSmall.copyWith(color: c.chromeDim),
        ),
        if (entry.description != null) ...[
          const SizedBox(height: 8),
          Text(
            entry.description!,
            style: ConsoleFonts.body13.copyWith(color: c.textLo),
          ),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 560
          ? Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 16),
                trailing,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: trailing),
              ],
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

class _TextEntry extends StatefulWidget {
  const _TextEntry({
    required this.entry,
    required this.initial,
    required this.validator,
    required this.onSave,
  });

  final ConfigEntry entry;
  final String initial;
  final String? Function(String) validator;
  final Future<void> Function(String) onSave;

  @override
  State<_TextEntry> createState() => _TextEntryState();
}

class _TextEntryState extends State<_TextEntry> {
  late final _c = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _c.text != widget.initial;
    return _EntryLayout(
      entry: widget.entry,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: TextField(
              controller: _c,
              style: ConsoleFonts.monoSmall.copyWith(
                fontSize: 14,
                color: context.console.textHi,
              ),
              decoration: InputDecoration(errorText: _error),
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: dirty
                ? () {
                    final err = widget.validator(_c.text.trim());
                    if (err != null) {
                      setState(() => _error = err);
                    } else {
                      widget.onSave(_c.text.trim());
                    }
                  }
                : null,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
