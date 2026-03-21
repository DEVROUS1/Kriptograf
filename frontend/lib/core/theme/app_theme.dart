import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Pro Terminal - Deep Dark Colors
  static const Color _primary = Color(0xFF5E54FF); // Daha sofistike bir mor
  static const Color _bg = Color(0xFF07080E); // Tam karanlık uzay siyahı
  static const Color _surface = Color(0xFF11121C); // Widget arkaplanları
  static const Color _surfaceVariant = Color(0xFF1A1C29);
  static const Color _bullish = Color(0xFF00E676); // Neondan çok parlak yeşil
  static const Color _bearish = Color(0xFFFF3366); // Sert kararlı kırmızı
  static const Color _warning = Color(0xFFFFD32A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          headlineLarge: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          headlineMedium: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          titleLarge: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          titleMedium: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(color: Colors.white, fontSize: 14),
          bodyMedium: const TextStyle(color: Color(0xFFB0B3C8), fontSize: 13),
          labelSmall: const TextStyle(color: Color(0xFF8890B0), fontSize: 11, letterSpacing: 0.2),
        )
      ),
      colorScheme: const ColorScheme.dark(
        primary: _primary,
        surface: _surface,
        surfaceContainerHighest: _surfaceVariant,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: _bg,
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        margin: EdgeInsets.zero,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: _primary,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.4),
        indicatorColor: _primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white.withValues(alpha: 0.8)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.05),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static const Color bullish = _bullish;
  static const Color bearish = _bearish;
  static const Color primary = _primary;
  static const Color background = _bg;
  static const Color surface = _surface;
  static const Color surfaceVariant = _surfaceVariant;
  static const Color warning = _warning;
}