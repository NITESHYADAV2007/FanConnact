// Big, Instagram-post-style news card used in the Home feed.

import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';

class NewsPostCard extends StatelessWidget {
  final NewsItem item;

  const NewsPostCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final desc = item.description ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: sport avatar + source + time
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.brandBlue.withValues(alpha: 0.15),
                  child: Text(
                    item.sportEmoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.source,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.timeAgo.isNotEmpty)
                        Text(
                          item.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.tag,
                    style: const TextStyle(
                      color: AppColors.brandBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Big image header
          if (item.image != null && item.image!.isNotEmpty)
            Image.network(
              item.image!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, prog) =>
                  prog == null ? child : Container(height: 200, color: Colors.grey.shade800),
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: AppColors.brandBlue.withValues(alpha: 0.2),
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 40, color: Colors.white54),
                ),
              ),
            ),

          // Title + description
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.3,
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                _stat(Icons.favorite_outline, 'Like', isDark),
                const SizedBox(width: 18),
                _stat(Icons.chat_bubble_outline, 'Comment', isDark),
                const Spacer(),
                if (item.link != null && item.link!.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      // Open in browser would use url_launcher; kept simple.
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Read'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandBlue,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
