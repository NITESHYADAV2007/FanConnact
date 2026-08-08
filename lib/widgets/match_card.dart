import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../screens/match_detail_screen.dart';

class MatchCard extends StatelessWidget {
  final MatchItem match;
  final VoidCallback? onTap;
  final void Function(String teamName, String? logo)? onTeamTap;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
    this.onTeamTap,
  });

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

  String _statusLabel() {
    switch (match.status) {
      case 'LIVE':
        return '● LIVE';
      case 'UPCOMING':
        return 'Starts at ${match.time}';
      default:
        return 'Finished';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1a1f2e) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2a2f3e) : const Color(0xFFe8ecf0);

    return InkWell(
      onTap: onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MatchDetailScreen(match: match),
              ),
            );
          },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            children: [
              // Team A row
              _buildTeamRow(
                name: match.teamA,
                abbr: match.abbrA,
                logo: match.logoA,
                score: match.scoreA,
                overs: match.overA,
                isRight: false,
              ),
              const SizedBox(height: 8),
              // Divider with vs
              Row(
                children: [
                  Expanded(child: Divider(color: borderColor, thickness: 0.5)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('VS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white24 : Colors.black12, letterSpacing: 1)),
                  ),
                  Expanded(child: Divider(color: borderColor, thickness: 0.5)),
                ],
              ),
              const SizedBox(height: 8),
              // Team B row
              _buildTeamRow(
                name: match.teamB,
                abbr: match.abbrB,
                logo: match.logoB,
                score: match.scoreB,
                overs: match.overB,
                isRight: true,
              ),
              const SizedBox(height: 10),
              // Footer: status + time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (match.matchType != null && match.matchType!.isNotEmpty)
                    Text(
                      match.matchType!,
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w600),
                    ),
                  if (match.venue != null && match.venue!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.location_on_outlined, size: 12, color: isDark ? Colors.white24 : Colors.black26),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        match.venue!,
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRow({
    required String name,
    String? abbr,
    String? logo,
    String? score,
    String? overs,
    required bool isRight,
  }) {
    final abbrText = abbr ?? (name.length > 12 ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join() : name.substring(0, name.length > 8 ? 8 : name.length));

    return GestureDetector(
      onTap: onTeamTap != null ? () => onTeamTap!(name, logo) : null,
      child: Row(
        textDirection: isRight ? TextDirection.rtl : TextDirection.ltr,
        children: [
          // Logo
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: logo != null && logo.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(logo, width: 32, height: 32, fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _defaultIcon()),
                  )
                : _defaultIcon(),
          ),
          const SizedBox(width: 10),
          // Name + overs
          Expanded(
            child: Column(
              crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  abbrText,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                  overflow: TextOverflow.ellipsis,
                ),
                if (overs != null)
                  Text('$overs ov', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Score
          if (score != null)
            Text(
              score,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: isRight ? const Color(0xFF1a73e8) : const Color(0xFFe81a1a),
              ),
            ),
        ],
      ),
    );
  }

  Widget _defaultIcon() {
    return const Icon(Icons.sports, size: 18, color: Color(0xFF64748B));
  }
}
