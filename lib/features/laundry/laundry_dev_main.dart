import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'presentation/laundry_page.dart';

// Private entry point used only to test the laundry module.
// This file does NOT replace the team's main.dart.
void main() {
  runApp(const LaundryDevApp());
}

class LaundryDevApp extends StatelessWidget {
  const LaundryDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResiDry - Linge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LaundryPage(),
    );
  }
}