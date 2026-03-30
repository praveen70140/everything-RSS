import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../../core/theme/app_colors.dart';

class DenseArticleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? author;
  final DateTime? pubDate;
  final bool isRead;
  final VoidCallback? onTap;

  const DenseArticleTile({
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
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
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
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  if (author != null && pubDate != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text('•',
                          style: TextStyle(
                              color: AppColors.overlay0, fontSize: 10)),
                    ),
                  if (pubDate != null)
                    Text(
                      timeago.format(pubDate!),
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        color: AppColors.overlay0,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6),
            ],
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                color: isRead ? AppColors.subtext1 : AppColors.text,
                height: 1.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: isRead ? AppColors.overlay0 : AppColors.subtext1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}