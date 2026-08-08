import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bgFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _logoFade;
  late Animation<Offset> _batSlide;
  late Animation<double> _batFade;
  late Animation<Offset> _ballSlide;
  late Animation<double> _ballFade;
  late Animation<double> _sportsFade;
  late Animation<double> _chatFade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _bgFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn)));

    _logoFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.15, 0.4, curve: Curves.easeIn)));
    _logoSlide = Tween<Offset>(
            begin: const Offset(0, -0.6), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve:
                const Interval(0.15, 0.4, curve: Curves.easeOutBack)));

    _batFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.25, 0.5, curve: Curves.easeIn)));
    _batSlide = Tween<Offset>(
            begin: const Offset(-2.5, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve:
                const Interval(0.25, 0.5, curve: Curves.easeOutCubic)));

    _ballFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.55, curve: Curves.easeIn)));
    _ballSlide = Tween<Offset>(
            begin: const Offset(2.5, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve:
                const Interval(0.3, 0.55, curve: Curves.easeOutCubic)));

    _sportsFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.7, curve: Curves.easeIn)));

    _chatFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.65, 0.85, curve: Curves.easeIn)));

    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.85, 1.0, curve: Curves.easeInOut)));

    _ctrl.forward();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Scaffold(
          backgroundColor: const Color(0xFF02060C),
          body: Stack(
            children: [
              // Stadium background
              Opacity(
                opacity: _bgFade.value,
                child: const _StadiumBg(),
              ),
              Center(
                child: Transform.scale(
                  scale: _scale.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Transform.translate(
                        offset: Offset(
                            0, _logoSlide.value.dy * 80),
                        child: Opacity(
                          opacity: _logoFade.value,
                          child: Image.asset(
                            'assets/fancoin/fanconnactlogo.png',
                            height: 72,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.sports,
                                    size: 64,
                                    color: Color(0xFF10B981)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Sports icons row
                      Opacity(
                        opacity: _sportsFade.value,
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            _sportIcon(Icons.sports_cricket,
                                const Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            _sportIcon(Icons.sports_soccer,
                                const Color(0xFF2196F3)),
                            const SizedBox(width: 8),
                            _sportIcon(Icons.sports_baseball,
                                const Color(0xFFFF9800)),
                            const SizedBox(width: 8),
                            _sportIcon(Icons.sports_basketball,
                                const Color(0xFFE53935)),
                            const SizedBox(width: 8),
                            _sportIcon(Icons.sports_tennis,
                                const Color(0xFF9C27B0)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Bat + Ball + Chat
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          // Bat
                          Transform.translate(
                            offset: Offset(
                                _batSlide.value.dx * 60,
                                _batSlide.value.dy * 60),
                            child: Opacity(
                              opacity: _batFade.value,
                              child: const _SportChip(
                                icon: Icons.sports_cricket,
                                label: 'BAT',
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Ball
                          Transform.translate(
                            offset: Offset(
                                _ballSlide.value.dx * 60,
                                _ballSlide.value.dy * 60),
                            child: Opacity(
                              opacity: _ballFade.value,
                              child: const _SportChip(
                                icon: Icons.sports_baseball,
                                label: 'BALL',
                                color: Color(0xFFFF9800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Chat
                          Opacity(
                            opacity: _chatFade.value,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3)
                                    .withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(
                                            0xFF2196F3)
                                        .withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble,
                                      size: 18,
                                      color: Color(0xFF2196F3)),
                                  SizedBox(width: 4),
                                  Text('CHAT',
                                      style: TextStyle(
                                        color:
                                            Color(0xFF2196F3),
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight.w800,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Tagline
                      Opacity(
                        opacity: _chatFade.value,
                        child: Text(
                          'Connect. Predict. Win.',
                          style: TextStyle(
                            color: Colors.white.withValues(
                                alpha: 0.6),
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sportIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _SportChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SportChip(
      {required this.icon,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              )),
        ],
      ),
    );
  }
}

class _StadiumBg extends StatelessWidget {
  const _StadiumBg();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _StadiumPainter(),
      ),
    );
  }
}

class _StadiumPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fillPaint = Paint()..style = PaintingStyle.fill;

    // Outer glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.08),
          const Color(0xFF02060C),
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(centerX, centerY), radius: size.width));
    canvas.drawRect(Offset.zero & size, glow);

    // Stadium ellipse
    paint.color =
        const Color(0xFF10B981).withValues(alpha: 0.15);
    paint.strokeWidth = 2;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(centerX, centerY * 0.85),
            width: size.width * 0.85,
            height: size.height * 0.55),
        paint);

    // Inner ellipse
    paint.color =
        const Color(0xFF10B981).withValues(alpha: 0.08);
    paint.strokeWidth = 1;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(centerX, centerY * 0.85),
            width: size.width * 0.65,
            height: size.height * 0.35),
        paint);

    // Stadium vertical lines (stands)
    paint.color =
        const Color(0xFF10B981).withValues(alpha: 0.06);
    paint.strokeWidth = 1;
    for (var i = -3; i <= 3; i++) {
      if (i == 0) continue;
      final x = centerX + i * (size.width * 0.1);
      canvas.drawLine(
        Offset(x, centerY * 0.55),
        Offset(x, centerY * 1.1),
        paint,
      );
    }

    // Horizontal stand lines
    for (var i = 1; i <= 3; i++) {
      paint.color = const Color(0xFF10B981)
          .withValues(alpha: 0.04 * i);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(centerX, centerY * 0.85),
              width: size.width * (0.85 - i * 0.08),
              height: size.height * (0.55 - i * 0.08)),
          paint);
    }

    // Small dots around the stadium (floodlights)
    paint.color =
        const Color(0xFF10B981).withValues(alpha: 0.2);
    fillPaint.color =
        const Color(0xFF10B981).withValues(alpha: 0.15);
    for (var i = 0; i < 6; i++) {
      final angle = i * (3.14159 / 3) - 3.14159 / 2;
      final rx = size.width * 0.425;
      final ry = size.height * 0.275;
      final x = centerX + rx * 0.9 * cos(angle);
      final y = centerY * 0.85 + ry * 0.9 * sin(angle);
      canvas.drawCircle(Offset(x, y), 4, fillPaint);
      canvas.drawCircle(Offset(x, y), 4, paint);
    }

    // Ground line
    paint.color =
        const Color(0xFF10B981).withValues(alpha: 0.1);
    paint.strokeWidth = 1;
    canvas.drawLine(
      Offset(centerX - size.width * 0.2, centerY * 1.2),
      Offset(centerX + size.width * 0.2, centerY * 1.2),
      paint,
    );

    // Field oval
    paint.color =
        const Color(0xFF10B981).withValues(alpha: 0.05);
    fillPaint.color =
        const Color(0xFF10B981).withValues(alpha: 0.03);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(centerX, centerY * 0.9),
            width: size.width * 0.25,
            height: size.height * 0.08),
        fillPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(centerX, centerY * 0.9),
            width: size.width * 0.25,
            height: size.height * 0.08),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      false;
}
