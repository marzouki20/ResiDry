import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'presentation/laundry_list_screen.dart';

// A private entry point to test ONLY the laundry module,
// without touching the team's main.dart or app.dart.
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
      home: const LaundryListScreen(),
    );
  }
}