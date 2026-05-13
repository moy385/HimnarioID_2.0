import 'package:flutter/material.dart';

/// Temas de la aplicación HimnarioID 2.0
class AppTheme {
  AppTheme._();

  // ─── Colores de la marca ───
  static const Color primaryColor = Color(0xFF1A237E); // Azul profundo
  static const Color secondaryColor = Color(0xFFC5A55A); // Dorado
  static const Color backgroundColor = Color(0xFF121212); // Casi negro
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);

  // ─── Tema Claro ───
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: primaryColor,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );

  // ─── Tema Oscuro (ideal para proyección) ───
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: surfaceColor,
    ),
    cardTheme: const CardThemeData(
      color: surfaceColor,
      elevation: 2,
    ),
  );

  // ─── Tema de Proyección (Display - PC/TV) ───
  // Sin decoraciones, fondo negro puro, texto gigante
  static final ThemeData projectionTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      surface: Colors.black,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.4,
      ),
      displayMedium: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 36,
        color: Colors.white,
        height: 1.6,
      ),
    ),
  );
}
