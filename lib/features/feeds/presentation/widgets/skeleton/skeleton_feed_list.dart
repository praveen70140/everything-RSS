import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../core/theme/app_colors.dart';

class SkeletonFeedList extends StatelessWidget {
  final int itemCount;

  const SkeletonFeedList({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          Divider(color: AppColors.surface1, height: 1),
      itemBuilder: (context, index) {
        // Varying widths to make it look somewhat natural
        final titleWidth = index % 2 == 0 ? 0.9 : 0.7;
        final subtitleLines = index % 3 == 0 ? 3 : 2;

        return Shimmer.fromColors(
          baseColor: AppColors.surface0,
          highlightColor: AppColors.surface1,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author & Date line
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Title line 1
                Container(
                  width: MediaQuery.of(context).size.width * titleWidth,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Title line 2 (sometimes)
                if (index % 2 != 0) ...[
                  Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const SizedBox(height: 4),
                ],
                // Subtitle lines
                for (int i = 0; i < subtitleLines; i++) ...[
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
