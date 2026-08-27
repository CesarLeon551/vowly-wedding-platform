import 'package:flutter/material.dart';

/// Design tokens de la app.
/// Paleta pensada para sentirse elegante/romántica sin caer en lo infantil:
/// tonos tierra + blush + un acento oscuro para contraste y legibilidad.
class AppColors {
  AppColors._();

  static const blush = Color(0xFFE8C9C2);
  static const terracotta = Color(0xFFC97C5D);
  static const ink = Color(0xFF2B2420);
  static const cream = Color(0xFFFBF6F1);
  static const sage = Color(0xFF8A9A80);
  static const gold = Color(0xFFB8965F);
  static const danger = Color(0xFFB3452B);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.terracotta,
        primary: AppColors.terracotta,
        secondary: AppColors.gold,
        surface: AppColors.cream,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: 'Georgia', // reemplazar por una fuente serif + sans-serif
                              // (p.ej. Playfair Display + Inter) vía google_fonts
                              // cuando se defina la identidad visual final.
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.blush.withOpacity(0.6)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.blush),
        ),
      ),
    );
  }
}
