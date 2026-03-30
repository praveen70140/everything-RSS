import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../../core/theme/app_colors.dart';

class ArticleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? author;
  final DateTime? pubDate;
  final bool isRead;
  final VoidCallback? onTap;

  const ArticleTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.author,
    this.pubDate,
    this.isRead = false,
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
            if (author != null || pubDate != null) ...[
              Row(
                children: [
                  if (author != null)
                    Expanded(
                      child: Text(
                        author!.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  if (author != null && pubDate != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('•',
                          style: TextStyle(
                              color: AppColors.overlay0, fontSize: 12)),
                    ),
                  if (pubDate != null)
                    Text(
                      timeago.format(pubDate!),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.overlay0,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),
            ],
            Text(
              title,
              style: GoogleFonts.epilogue(
                fontSize: 24,
                fontWeight: isRead ? FontWeight.w600 : FontWeight.w900,
                color: isRead ? AppColors.subtext1 : AppColors.text,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: isRead ? AppColors.overlay0 : AppColors.subtext1,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}