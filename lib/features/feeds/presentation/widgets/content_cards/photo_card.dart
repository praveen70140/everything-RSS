import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../../core/theme/app_colors.dart';
import 'feed_card_styles.dart';

class PhotoCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String? author;
  final DateTime? pubDate;
  final bool isRead;
  final VoidCallback? onTap;

  const PhotoCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.author,
    this.pubDate,
    this.isRead = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: AppColors.crust,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Icon(Icons.broken_image, color: AppColors.surface1));
                },
              ),
            ),
          ),
          Padding(
            padding: FeedCardStyles.mediaTextPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (author != null || pubDate != null) ...[
                  Row(
                    children: [
                      if (author != null && author!.isNotEmpty)
                        Expanded(
                          child: Text(
                            author!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FeedCardStyles.metadata(color: AppColors.blue),
                          ),
                        ),
                      if (author != null &&
                          author!.isNotEmpty &&
                          pubDate != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('•',
                              style: TextStyle(
                                  color: AppColors.overlay0, fontSize: 12)),
                        ),
                      if (pubDate != null)
                        Text(
                          timeago.format(pubDate!),
                          style: FeedCardStyles.metadata(color: AppColors.overlay0),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  title,
                  style: FeedCardStyles.title(isRead: isRead),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FeedCardStyles.subtitle(isRead: isRead),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
