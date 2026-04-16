import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';

class FeedCardStyles {
  static const horizontalPadding = 24.0;
  static const metadataSize = 13.0;
  static const titleSize = 22.0;
  static const denseTitleSize = 18.0;
  static const subtitleSize = 15.0;

  static EdgeInsets get articlePadding =>
      const EdgeInsets.symmetric(vertical: 20, horizontal: horizontalPadding);

  static EdgeInsets get mediaTextPadding =>
      const EdgeInsets.symmetric(vertical: 16, horizontal: horizontalPadding);

  static TextStyle metadata({Color? color}) => GoogleFonts.manrope(
        fontSize: metadataSize,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.blue,
      );

  static TextStyle title({required bool isRead}) => GoogleFonts.epilogue(
        fontSize: titleSize,
        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
        color: isRead ? AppColors.subtext1 : AppColors.text,
        height: 1.25,
        letterSpacing: -0.2,
      );

  static TextStyle denseTitle({required bool isRead}) => GoogleFonts.manrope(
        fontSize: denseTitleSize,
        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
        color: isRead ? AppColors.subtext1 : AppColors.text,
        height: 1.3,
      );

  static TextStyle subtitle({required bool isRead}) => GoogleFonts.manrope(
        fontSize: subtitleSize,
        color: isRead ? AppColors.overlay0 : AppColors.subtext1,
        height: 1.5,
      );
}
