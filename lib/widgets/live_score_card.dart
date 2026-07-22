import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets/glow_wrapper.dart';

// Compact horizontal "scorecard" used in the Home live-scores carousel.
class LiveScoreCard extends StatelessWidget {
  final MatchItem match;
  final VoidCallback? onTap;
  const LiveScoreCard({super.key, required this.match, this.onTap});

  Color _statusColor() {
    switch (match.status) {
      case 'LIVE':
        return AppColors.liveRed;
      case 'UPCOMING':
        return AppColors.upcomingAmber;
      default:
        return AppColors.completedGrey;
    }
  }

  Widget _team(String name, String? logo, String? score) {
    return Expanded(
      child: Row(
        children: [
          if (logo != null)
            GlowWrapper(
              glowColor: AppColors.brandBlue,
              glowBlur: 8,
              glowSpread: 1,
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                logo,
                width: 22,
                height: 22,
              errorBuilder: (_, _, _) =>
                    const Icon(Icons.sports, size: 18),
              ),
            )
          else
            const Icon(Icons.sports, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (score != null) ...[
            const SizedBox(width: 4),
            Text(
              score,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final live = match.status == 'LIVE';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(match.sportEmoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  match.series,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    if (live) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _statusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      match.status,
                      style: TextStyle(
                        color: _statusColor(),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _team(match.teamA, match.logoA, match.scoreA),
          const SizedBox(height: 8),
          _team(match.teamB, match.logoB, match.scoreB),
          const SizedBox(height: 8),
          Text(
            match.time,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
