import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/reels_service.dart';

class ReelsCard extends StatelessWidget {
  final ReelItem reel;
  final bool isDark;
  final VoidCallback? onTap;

  const ReelsCard({super.key, required this.reel, required this.isDark, this.onTap});

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final caption = reel.caption.isNotEmpty ? reel.caption : 'Sports reel';
    final shortCaption = caption.length > 90 ? '${caption.substring(0, 90)}…' : caption;

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
      child: InkWell(
        onTap: onTap,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail / video preview area
          AspectRatio(
            aspectRatio: 9 / 11,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (reel.thumb.isNotEmpty)
                  Image.network(
                    reel.thumb,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, prog) =>
                        prog == null ? child : Container(color: Colors.grey.shade800),
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.brandBlue.withOpacity(0.25)),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.brandBlue, AppColors.brandBlueDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                // Dark gradient overlay for legibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
                // Play button for videos
                if (reel.isVideo)
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      size: 56,
                      color: Colors.white70,
                    ),
                  ),
                // LIVE / VIDEO badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: reel.isVideo ? AppColors.liveRed : Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      reel.isVideo ? 'REEL' : 'POST',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // Caption at bottom
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reel.username != null)
                        Text(
                          '@${reel.username}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        shortCaption,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _stat(Icons.favorite_outline, _formatCount(reel.likeCount)),
                const SizedBox(width: 16),
                _stat(Icons.chat_bubble_outline, _formatCount(reel.commentCount)),
                const Spacer(),
                if (reel.isVideo && reel.viewCount > 0)
                  _stat(Icons.visibility_outlined, _formatCount(reel.viewCount)),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {},
                  child: Icon(
                    Icons.bookmark_border,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _stat(IconData icon, String label) {
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
