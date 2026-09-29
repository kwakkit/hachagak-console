import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/console_widgets.dart';
import '../../core/supabase.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await db.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return Scaffold(
      body: ConsoleBackdrop(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Wordmark(),
                  const SizedBox(height: 28),
                  BracketFrame(
                    child: ConsolePanel(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const ConsoleEyebrow('Admin · 관리자 인증'),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _email,
                              decoration: const InputDecoration(
                                labelText: '이메일',
                                prefixIcon: Icon(
                                  Icons.alternate_email,
                                  size: 18,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _password,
                              decoration: const InputDecoration(
                                labelText: '비밀번호',
                                prefixIcon: Icon(Icons.key_outlined, size: 18),
                              ),
                              obscureText: true,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => _signIn(),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              StatusPill(_error!, color: c.alert),
                            ],
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: _busy ? null : _signIn,
                              child: Text(_busy ? '확인 중…' : '로그인'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '등록된 관리자만 접속할 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: ConsoleFonts.body13.copyWith(
                      color: c.textLo,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final c = context.console;
    return Column(
      children: [
        Icon(Icons.hub_outlined, size: 30, color: c.accent),
        const SizedBox(height: 12),
        Text(
          '곽킷 콘솔',
          style: ConsoleFonts.pageTitle.copyWith(color: c.textHi, fontSize: 26),
        ),
        const SizedBox(height: 6),
        ConsoleEyebrow('Kwakkit · Operations Console', color: c.chrome),
      ],
    );
  }
}
