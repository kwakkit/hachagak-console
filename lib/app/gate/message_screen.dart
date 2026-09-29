import 'package:flutter/material.dart';

import '../../core/supabase.dart';
import '../console_widgets.dart';

/// 가운데 브라켓 패널 하나짜리 안내 화면.
class MessageScreen extends StatelessWidget {
  const MessageScreen({
    super.key,
    required this.title,
    required this.body,
    required this.color,
    this.showSignOut = false,
  });

  final String title;
  final String body;
  final Color color;
  final bool showSignOut;

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return Scaffold(
      body: ConsoleBackdrop(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BracketFrame(
                child: ConsolePanel(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusPill(title, color: color),
                      const SizedBox(height: 16),
                      SelectableText(
                        body,
                        style: ConsoleFonts.body13.copyWith(
                          color: c.textHi,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      if (showSignOut) ...[
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () => db.auth.signOut(),
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('로그아웃'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
