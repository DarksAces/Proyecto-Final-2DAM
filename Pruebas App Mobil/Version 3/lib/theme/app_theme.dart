import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color auraRed = Color(0xFFE30613);
  static const Color auraYellow = Color(0xFFFFCC00);
  static const Color auraBlue = Color(0xFF0099D8);

  static const Color backgroundWhite = Color(0xFFFAFAFA);
  static const Color textBlack = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF757575);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: auraRed,
      scaffoldBackgroundColor: backgroundWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: auraRed,
        primary: auraRed,
        secondary: auraYellow,
        tertiary: auraBlue,
        surface: backgroundWhite,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textBlack,
        displayColor: textBlack,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: auraRed,
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
}
