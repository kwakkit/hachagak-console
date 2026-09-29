import 'package:flutter/material.dart';

import '../../../core/supabase.dart';

/// 로그아웃 아이콘 버튼.
class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: '로그아웃',
    icon: const Icon(Icons.logout),
    onPressed: () => db.auth.signOut(),
  );
}
