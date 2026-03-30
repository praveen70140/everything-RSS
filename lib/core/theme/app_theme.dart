import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.base,
      brightness: AppColors.isDarkMode ? Brightness.dark : Brightness.light,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.base,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.mantle,
        elevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.epilogue(
          color: AppColors.text,
          fontWeight: FontWeight.w900,
        ),
        bodyLarge: GoogleFonts.manrope(
          color: AppColors.text,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.manrope(
          color: AppColors.subtext1,
        ),
      ),
    );
  }
}
