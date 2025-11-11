/// Tema de la aplicación con Material 3
/// 
/// Define los temas claro y oscuro con un esquema de colores personalizado
/// para la visualización de anomalías viales (huecos y grietas).
library;

import 'package:flutter/material.dart';

/// Color primario de la aplicación (Azul)
const Color primaryColor = Color(0xFF2196F3);

/// Color para representar huecos (Rojo)
const Color huecoColor = Color(0xFFFF0000);

/// Color para representar grietas (Naranja)
const Color grietaColor = Color(0xFFFF8800);

/// Tema claro de la aplicación
class AppTheme {
  /// Obtiene el tema claro con Material 3
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.white,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Obtiene el tema oscuro con Material 3
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.grey[900],
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Construye el TextTheme con estilos predefinidos
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseTextTheme = brightness == Brightness.light
        ? Typography.material2021().black
        : Typography.material2021().white;

    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12,
      ),
    );
  }

  /// Obtiene el color según el tipo de detección
  static Color getColorByType(String type) {
    switch (type.toLowerCase()) {
      case 'hueco':
        return huecoColor;
      case 'grieta':
        return grietaColor;
      default:
        return primaryColor;
    }
  }
}

