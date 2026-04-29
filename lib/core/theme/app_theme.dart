import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
      ),
      fontFamily: 'PressStart2P',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          color: AppColors.textPrimary,
          fontFamily: 'PressStart2P',
        ),
        bodyLarge: TextStyle(
          fontSize: 12,
          color: AppColors.textPrimary,
          fontFamily: 'PressStart2P',
        ),
        bodyMedium: TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontFamily: 'PressStart2P',
        ),
      ),
    );
  }
}
