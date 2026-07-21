import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color deepNavy = Color(0xFF0D0B1E);
  static const Color darkPurple = Color(0xFF1A1533);
  static const Color mediumPurple = Color(0xFF2D2654);
  static const Color softLavender = Color(0xFFB8A9E8);
  static const Color sleepPurple = Color(0xFF9B7ED8);
  static const Color sleepGlow = Color(0xFF7C5CBF);
  static const Color wakeYellow = Color(0xFFFFD93D);
  static const Color feedOrange = Color(0xFFE87A5D);
  static const Color feedTerracotta = Color(0xFFD46548);
  static const Color diaperTeal = Color(0xFF5DC9B8);
  static const Color diaperMint = Color(0xFF4ABBA8);
  static const Color textPrimary = Color(0xFFF0EEF6);
  static const Color textSecondary = Color(0xFF9892B5);
  static const Color textTertiary = Color(0xFF6B6590);
  static const Color cardDark = Color(0xFF1E1A3A);
  static const Color cardBorder = Color(0xFF2F2954);
  static const Color glowPurple = Color(0xFF6C4FBF);
  static const Color success = Color(0xFF5DC9B8);
  static const Color error = Color(0xFFE87A5D);

  static const Color starColor = Color(0x80FFFFFF);

  static Color eventColor(String type) {
    switch (type) {
      case 'sleep':
        return sleepPurple;
      case 'feed':
        return feedOrange;
      case 'pee':
        return diaperTeal;
      case 'poop':
        return diaperMint;
      default:
        return softLavender;
    }
  }
}
