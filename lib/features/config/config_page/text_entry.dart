import 'package:flutter/material.dart';

import '../../../app/console_widgets.dart';
import '../config_entry.dart';
import 'entry_layout.dart';

/// 문자열·JSON 값 편집 — 바뀌었을 때만 저장 버튼 활성, 저장 전 [validator] 로 검사.
class TextEntry extends StatefulWidget {
  const TextEntry({
    super.key,
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
  State<TextEntry> createState() => _TextEntryState();
}

class _TextEntryState extends State<TextEntry> {
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
    return EntryLayout(
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
