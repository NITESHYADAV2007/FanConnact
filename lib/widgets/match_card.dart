import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';

class MatchCard extends StatelessWidget {
  final MatchItem match;

  const MatchCard({super.key, required this.match});

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        children: [
          // Top accent bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: const LinearGradient(
                colors: [AppColors.brandBlue, AppColors.brandBlueDark],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(match.sportEmoji,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.series,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandBlue,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (match.status == 'LIVE')
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: AppColors.liveRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            match.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _statusColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TeamRow(
                        name: match.teamA,
                        logo: match.logoA,
                        score: match.scoreA,
                      ),
                    ),
                    const Text('  vs  ',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Expanded(
                      child: _TeamRow(
                        name: match.teamB,
                        logo: match.logoB,
                        score: match.scoreB,
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 15, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(match.time,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String name;
  final String? logo;
  final String? score;
  final bool alignRight;

  const _TeamRow({
    required this.name,
    this.logo,
    this.score,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoWidget = logo != null && logo!.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              logo!,
              width: 38,
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.sports, size: 30),
            ),
          )
        : const Icon(Icons.sports, size: 30);

    final children = [
      logoWidget,
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (score != null) ...[
        const SizedBox(width: 10),
        Text(
          score!,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.brandBlue),
        ),
      ],
    ];
    return Row(
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignRight ? children.reversed.toList() : children,
    );
  }
}
