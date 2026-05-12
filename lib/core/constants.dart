import 'package:flutter/material.dart';

// 🔐 API KEY
const String GEMINI_API_KEY = 'AIzaSyDYnKHQ30TkhUu3Q6goCQkhTPbnCaMuI24'
;

class AppSizes {
  AppSizes._();

  // Spacing
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  // Radii
  static const double smRadius = 10;
  static const double inputRadius = 14;
  static const double cardRadius = 18;
  static const double buttonRadius = 16;
}

class AppColors {
  AppColors._();

  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonPurple = Color(0xFFBB86FC);
  static const Color neonPink = Color(0xFFFF006E);
  static const Color neonOrange = Color(0xFFFF9100);
  static const Color neonYellow = Color(0xFFFFEA00);

  static const Color surface = Color(0xFF1E1E2C);
  static const Color surfaceLight = Color(0xFF2A2A3D);
  static const Color surfaceLighter = Color(0xFF353550);
  static const Color background = Color(0xFF121220);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted = Color(0xFF6E6E80);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF29B6F6);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonCyan, neonGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardGradient => const LinearGradient(
        colors: [neonCyan, neonGreen],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
