import 'package:flutter/material.dart';

ThemeData buildLightTheme(ColorScheme scheme) {
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    textTheme: Typography.englishLike2021.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      surfaceTintColor: scheme.surfaceTint,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

ThemeData buildDarkTheme(ColorScheme scheme) {
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    textTheme: Typography.englishLike2021.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      surfaceTintColor: scheme.surfaceTint,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

ColorScheme lightColorScheme() {
  return const ColorScheme.light(
    primary: Color(0xFF0061A4),
    secondary: Color(0xFF5851D8),
    tertiary: Color(0xFF00A47F),
    surface: Color(0xFFF5F7FA),
    surfaceTint: Color(0xFFE7F1FF),
  );
}

ColorScheme darkColorScheme() {
  return const ColorScheme.dark(
    primary: Color(0xFF72C6FF),
    secondary: Color(0xFFBBB3FF),
    tertiary: Color(0xFF5ADBB5),
    surface: Color(0xFF1B1F23),
    surfaceTint: Color(0xFF2B2F33),
  );
}
