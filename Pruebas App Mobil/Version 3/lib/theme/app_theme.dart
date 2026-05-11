import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color arteRed = Color(0xFFE30613);
  static const Color arteYellow = Color(0xFFFFCC00);
  static const Color arteBlue = Color(0xFF0099D8);
  static const Color arteGreen = Color(0xFF4CAF50);

  static const Color backgroundWhite = Color(0xFFFAFAFA);
  static const Color textBlack = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF757575);
  static const Color backgroundBlack = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: arteRed,
      scaffoldBackgroundColor: backgroundWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: arteRed,
        primary: arteRed,
        secondary: arteYellow,
        tertiary: arteBlue,
        surface: backgroundWhite,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textBlack,
        displayColor: textBlack,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: arteRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: textBlack,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: textBlack),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: arteRed,
      scaffoldBackgroundColor: backgroundBlack,
      colorScheme: ColorScheme.fromSeed(
        seedColor: arteRed,
        primary: arteRed,
        secondary: arteYellow,
        tertiary: arteBlue,
        surface: surfaceDark,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: arteRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
