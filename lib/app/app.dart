import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'theme/app_theme.dart';

class SurtioApp extends StatelessWidget {
  const SurtioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Surtio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
