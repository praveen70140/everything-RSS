import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class ArticleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const ArticleTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.epilogue(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: AppColors.subtext1,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
