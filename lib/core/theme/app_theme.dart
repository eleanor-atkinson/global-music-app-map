import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppTheme {
  // Brand colours
  static const _primary = Color(0xFF6366F1);    // indigo
  static const _background = Color(0xFF0A0A0F); // near-black
  static const _surface = Color(0xFF16161F);
  static const _onSurface = Color(0xFFF0F0F5);
  static const _muted = Color(0xFF6B6B80);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _background,
      colorScheme: const ColorScheme.dark(
        primary: _primary,
        background: _background,
        surface: _surface,
        onSurface: _onSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: _onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        bodyMedium: TextStyle(color: _onSurface, fontSize: 14),
        bodySmall: TextStyle(color: _muted, fontSize: 12),
      ),
    );
  }
}
