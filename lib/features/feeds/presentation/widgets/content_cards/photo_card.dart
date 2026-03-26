import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class PhotoCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  const PhotoCard({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: AppColors.surface0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.error));
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: Text(
              title,
              style: GoogleFonts.epilogue(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}