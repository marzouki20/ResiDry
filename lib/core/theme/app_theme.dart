import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF1E3A8A);
  static const cyan = Color(0xFF06B6D4);
  static const coral = Color(0xFFFF8B8B);
  static const cream = Color(0xFFF8F6F0);

  static const ink = navy;
  static const muted = Color(0xFF5F6F97);
  static const purple = cyan;
  static const canvas = cream;
  static const line = Color(0xFFDDE5F6);

  const AppColors._();
}

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
    fontFamily: 'Roboto',
  );

  const AppTheme._();
}
