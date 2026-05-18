import 'package:flutter/material.dart';

final temaApp = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF161342),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF161342),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF252A4D),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF7C5CFF),
        width: 2,
      ),
    ),
    hintStyle: const TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 14,
    ),
    labelStyle: const TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 14,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF7C5CFF),
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF7C5CFF),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: const Color(0xFF252A4D).withOpacity(0.9),
    indicatorColor: const Color(0xFF7C5CFF).withOpacity(0.3),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
    iconTheme: WidgetStateProperty.all(
      const IconThemeData(
        size: 28,
      ),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: Colors.white,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    displaySmall: TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: Colors.white,
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 12,
    ),
    labelLarge: TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  ),
);
