import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF20202B);
  static const muted = Color(0xFF858493);
  static const purple = Color(0xFF7457E8);
  static const canvas = Color(0xFFF8F7FC);
  static const line = Color(0xFFEAE9F0);

  const AppColors._();
}

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.purple),
    fontFamily: 'Roboto',
  );

  const AppTheme._();
}
