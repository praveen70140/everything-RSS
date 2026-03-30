import 'package:flutter/material.dart';

class AppColors {
  static bool isDarkMode = true;

  static Color get base =>
      isDarkMode ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5);
  static Color get mantle =>
      isDarkMode ? const Color(0xFF181825) : const Color(0xFFE6E9EF);
  static Color get crust =>
      isDarkMode ? const Color(0xFF11111B) : const Color(0xFFDCE0E8);
  static Color get surface0 =>
      isDarkMode ? const Color(0xFF313244) : const Color(0xFFCCD0DA);
  static Color get surface1 =>
      isDarkMode ? const Color(0xFF45475A) : const Color(0xFFBCC0CC);

  static Color get text =>
      isDarkMode ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69);
  static Color get subtext1 =>
      isDarkMode ? const Color(0xFFBAC2DE) : const Color(0xFF5C5F77);
  static Color get overlay0 =>
      isDarkMode ? const Color(0xFF6C7086) : const Color(0xFF8C8FA1);

  static Color get blue =>
      isDarkMode ? const Color(0xFF89B4FA) : const Color(0xFF1E66F5);
  static Color get mauve =>
      isDarkMode ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);
  static Color get green =>
      isDarkMode ? const Color(0xFFA6E3A1) : const Color(0xFF40A02B);
  static Color get yellow =>
      isDarkMode ? const Color(0xFFF9E2AF) : const Color(0xFFDF8E1D);
  static Color get red =>
      isDarkMode ? const Color(0xFFF38BA8) : const Color(0xFFD20F39);
}
