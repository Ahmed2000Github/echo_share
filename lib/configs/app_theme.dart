import 'package:echo_share/configs/app_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static TextButtonThemeData textButtonThemeData = TextButtonThemeData(
    style: TextButton.styleFrom(
      fixedSize: Size(200, 40),
      foregroundColor: Colors.white, // Text color
      backgroundColor: AppColors.primary, // Background color
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding
      textStyle: const TextStyle(
        fontFamily: "Itim",
        fontSize: 14,
        color: Colors.white,
      ), // Text style
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4), // Button shape
      ),
    ),
  );
  static ThemeData light = ThemeData(
      primaryColor: AppColors.primary,
      textButtonTheme: textButtonThemeData,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: "Itim",
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          fontFamily: "Itim",
          fontSize: 20,
        ),
        bodyLarge: TextStyle(
          fontFamily: "Itim",
          fontSize: 14,
        ),
      ));
  static ThemeData dark = ThemeData(
      textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontFamily: "Itim",
      fontSize: 24,
    ),
    titleLarge: TextStyle(
      fontFamily: "Itim",
      fontSize: 20,
    ),
    bodyLarge: TextStyle(
      fontFamily: "Itim",
      fontSize: 14,
    ),
  ));
}
