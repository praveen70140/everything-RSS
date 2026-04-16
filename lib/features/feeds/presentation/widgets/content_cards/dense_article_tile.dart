import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../../core/theme/app_colors.dart';
import 'feed_card_styles.dart';

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
        padding: FeedCardStyles.articlePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (author != null || pubDate != null) ...[
              Row(
                children: [
                  if (author != null)
                    Expanded(
                      child: Text(
                        author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FeedCardStyles.metadata(color: AppColors.blue),
                      ),
                    ),
                  if (author != null && pubDate != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text('•',
                          style: TextStyle(
                              color: AppColors.overlay0,
                              fontSize: FeedCardStyles.metadataSize)),
                    ),
                  if (pubDate != null)
                    Text(
                      timeago.format(pubDate!),
                      style: FeedCardStyles.metadata(color: AppColors.overlay0),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              title,
              style: FeedCardStyles.denseTitle(isRead: isRead),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: FeedCardStyles.subtitle(isRead: isRead),
            ),
          ],
        ),
      ),
    );
  }
}
