import 'dart:math' as math;
import 'package:flutter/material.dart';

class SportEventOverlay extends StatefulWidget {
  final String sport;
  final String eventType;
  final String eventText;
  final String? playerName;
  final bool visible;

  const SportEventOverlay({
    super.key,
    required this.sport,
    required this.eventType,
    required this.eventText,
    this.playerName,
    this.visible = false,
  });

  @override
  State<SportEventOverlay> createState() => _SportEventOverlayState();
}

class _SportEventOverlayState extends State<SportEventOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  String? _lastKey;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );
  }

  @override
  void didUpdateWidget(covariant SportEventOverlay old) {
    super.didUpdateWidget(old);
    final key = '${widget.eventType}|${widget.eventText}';
    if (widget.visible && key != _lastKey) {
      _lastKey = key;
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildSportIcon() {
    switch (widget.sport) {
      case 'cricket':
        switch (widget.eventType.toUpperCase()) {
          case 'SIX':
            return _IconBadge(icon: Icons.flight, label: 'SIX!', color: const Color(0xFFFF9800));
          case 'FOUR':
          case 'BOUNDARY':
            return _IconBadge(icon: Icons.sports_handball, label: 'FOUR', color: const Color(0xFF2196F3));
          case 'WICKET':
            return _IconBadge(icon: Icons.broken_image, label: 'WICKET', color: const Color(0xFFE53935));
          case 'FIFTY':
            return _IconBadge(icon: Icons.emoji_events, label: '50 🎯', color: const Color(0xFF4CAF50));
          case 'CENTURY':
            return _IconBadge(icon: Icons.emoji_events, label: '100 🏆', color: const Color(0xFFFFD700));
          case 'HATTRICK':
            return _IconBadge(icon: Icons.stars, label: 'HAT-TRICK', color: const Color(0xFF9C27B0));
          default:
            return _IconBadge(icon: Icons.sports_cricket, label: widget.eventType, color: Colors.grey);
        }
      case 'football':
        switch (widget.eventType.toUpperCase()) {
          case 'GOAL':
            return _IconBadge(icon: Icons.sports_soccer, label: '⚽ GOAL!', color: const Color(0xFF4CAF50));
          case 'PENALTY':
            return _IconBadge(icon: Icons.warning, label: 'PENALTY!', color: const Color(0xFFFF9800));
          case 'RED_CARD':
            return _IconBadge(icon: Icons.block, label: '🔴 RED CARD', color: const Color(0xFFE53935));
          case 'YELLOW_CARD':
            return _IconBadge(icon: Icons.report, label: '🟡 YELLOW', color: const Color(0xFFFF9800));
          case 'FREE_KICK':
            return _IconBadge(icon: Icons.sports_handball, label: 'FREE KICK', color: const Color(0xFF2196F3));
          default:
            return _IconBadge(icon: Icons.sports_soccer, label: widget.eventType, color: Colors.grey);
        }
      case 'tennis':
        switch (widget.eventType.toUpperCase()) {
          case 'ACE':
            return _IconBadge(icon: Icons.sports_tennis, label: 'ACE!', color: const Color(0xFF2196F3));
          case 'BREAK_POINT':
            return _IconBadge(icon: Icons.trending_up, label: 'BREAK!', color: const Color(0xFFFF9800));
          case 'SET_POINT':
            return _IconBadge(icon: Icons.emoji_events, label: 'SET POINT', color: const Color(0xFF4CAF50));
          case 'MATCH_POINT':
            return _IconBadge(icon: Icons.emoji_events, label: 'MATCH POINT', color: const Color(0xFFFFD700));
          default:
            return _IconBadge(icon: Icons.sports_tennis, label: widget.eventType, color: Colors.grey);
        }
      case 'tabletennis':
        return _IconBadge(icon: Icons.sports_tennis, label: widget.eventType, color: const Color(0xFF2196F3));
      case 'hockey':
        if (widget.eventType.toUpperCase() == 'GOAL') {
          return _IconBadge(icon: Icons.sports_hockey, label: '🏑 GOAL!', color: const Color(0xFF4CAF50));
        }
        return _IconBadge(icon: Icons.sports_hockey, label: widget.eventType, color: Colors.grey);
      case 'volleyball':
        return _IconBadge(icon: Icons.sports_volleyball, label: widget.eventType, color: const Color(0xFF2196F3));
      case 'kabaddi':
        if (widget.eventType.toUpperCase() == 'ALL_OUT') {
          return _IconBadge(icon: Icons.block, label: 'ALL OUT!', color: const Color(0xFFE53935));
        }
        return _IconBadge(icon: Icons.sports_kabaddi, label: widget.eventType, color: const Color(0xFFFF9800));
      case 'baseball':
        if (widget.eventType.toUpperCase() == 'HOME_RUN') {
          return _IconBadge(icon: Icons.flight, label: '⚾ HOME RUN!', color: const Color(0xFFE53935));
        }
        return _IconBadge(icon: Icons.sports_baseball, label: widget.eventType, color: Colors.grey);
      case 'esports':
        return _IconBadge(icon: Icons.videogame_asset, label: widget.eventType, color: const Color(0xFF9C27B0));
      default:
        return _IconBadge(icon: Icons.sports, label: widget.eventType, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSportIcon(),
                  if (widget.playerName != null) ...[
                    const SizedBox(height: 6),
                    Text(widget.playerName!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 4),
                  Text(widget.eventText,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _IconBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1,
            )),
      ],
    );
  }
}

class _ScoreBarPainter extends CustomPainter {
  final double runRate;
  final bool isDark;

  _ScoreBarPainter(this.runRate, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2196F3).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final h = size.height;
    final w = size.width;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    final data = [4, 1, 6, 0, 2, 1, 3, 4, 0, 6, 1, 2, 1, 4, 0, 1];
    final barPaint = Paint();
    final barW = w / data.length;
    for (int i = 0; i < data.length; i++) {
      barPaint.color = data[i] >= 4 ? const Color(0xFF2196F3) : const Color(0xFFE53935);
      canvas.drawRect(
        Rect.fromLTWH(i * barW, h - data[i] * (h / 7), barW - 1, data[i] * (h / 7)),
        barPaint..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class GraphsView extends StatelessWidget {
  final bool isDark;
  final String sport;
  final String? teamA;
  final String? teamB;
  final String? scoreA;
  final String? scoreB;

  const GraphsView({
    super.key,
    required this.isDark,
    required this.sport,
    this.teamA,
    this.teamB,
    this.scoreA,
    this.scoreB,
  });

  int _parseRuns(String? s) {
    if (s == null || s.isEmpty) return 0;
    final m = RegExp(r'(\d+)').firstMatch(s);
    return m != null ? int.tryParse(m.group(1)!) ?? 0 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final a = _parseRuns(scoreA);
    final b = _parseRuns(scoreB);
    final maxV = [a, b, 1].reduce((x, y) => x > y ? x : y).toDouble();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text('Score Comparison',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2230) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              _BarGraph(label: teamA ?? 'Team A', value: a, max: maxV, color: const Color(0xFF2196F3)),
              const SizedBox(height: 8),
              _BarGraph(label: teamB ?? 'Team B', value: b, max: maxV, color: const Color(0xFFE53935)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Run Rate (Last 16 balls)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 12),
        Container(
          height: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2230) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: CustomPaint(size: const Size(double.infinity, 136), painter: _ScoreBarPainter(5.5, isDark)),
        ),
        const SizedBox(height: 20),
        Text('Run Distribution',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 12),
        Container(
          height: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2230) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 196),
            painter: _WagonWheelPainter(isDark),
          ),
        ),
      ],
    );
  }
}

class _BarGraph extends StatelessWidget {
  final String label;
  final int value;
  final double max;
  final Color color;
  const _BarGraph({required this.label, required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            Text('$value', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: max > 0 ? value / max : 0,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}

class _WagonWheelPainter extends CustomPainter {
  final bool isDark;
  _WagonWheelPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width < size.height ? size.width : size.height) / 2 - 14;
    final grid = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(Offset(cx, cy), r * i / 3, grid);
    }
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), grid);
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), grid);

    const shots = <List<double>>[
      [20, 0.9, 1], [55, 0.7, 0], [95, 1.0, 1], [140, 0.6, 0],
      [165, 0.85, 1], [200, 0.5, 0], [235, 0.95, 1], [270, 0.65, 0],
      [300, 0.8, 1], [330, 0.55, 0], [350, 0.9, 1], [75, 0.6, 0],
    ];
    final shotPaint = Paint()..strokeWidth = 2.5;
    for (final s in shots) {
      final rad = s[0] * math.pi / 180;
      final len = s[1];
      final boundary = s[2] == 1;
      final reach = boundary ? 1.0 : 0.7;
      final ex = cx + r * len * reach * math.sin(rad);
      final ey = cy - r * len * reach * math.cos(rad);
      shotPaint.color = boundary ? const Color(0xFFE53935) : const Color(0xFF2196F3);
      canvas.drawLine(Offset(cx, cy), Offset(ex, ey), shotPaint);
      canvas.drawCircle(Offset(ex, ey), boundary ? 4 : 3, Paint()..color = shotPaint.color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
