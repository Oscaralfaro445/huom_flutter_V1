import 'package:flutter/material.dart';

class AppColors {
  // Fondos
  static const Color background = Color(0xFF1A1A2E);
  static const Color backgroundSecondary = Color(0xFF16213E);
  static const Color surface = Color(0xFF0F3460);

  // Acento principal
  static const Color primary = Color(0xFFE94560);
  static const Color primaryLight = Color(0xFFFF6B8A);

  // Stats
  static const Color statHunger = Color(0xFFFF6B35);
  static const Color statMood = Color(0xFFFFD93D);
  static const Color statPlay = Color(0xFF6BCB77);
  static const Color statSleep = Color(0xFF4D96FF);
  static const Color statHealth = Color(0xFFFF6B8A);

  // Barras de stat por nivel
  static const Color statHigh = Color(0xFF6BCB77); // > 60%
  static const Color statMedium = Color(0xFFFFD93D); // 30–60%
  static const Color statLow = Color(0xFFFF6B35); // 15–30%
  static const Color statCritical = Color(0xFFE94560); // < 15%

  // Texto
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFF9E9E9E);

  // UI
  static const Color buttonBackground = Color(0xFF0F3460);
  static const Color buttonBorder = Color(0xFF4D96FF);
  static const Color cardBackground = Color(0xFF16213E);
}
