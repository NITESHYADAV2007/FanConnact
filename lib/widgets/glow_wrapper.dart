import 'package:flutter/material.dart';
import '../theme.dart';

// Wraps a child with a neon "overflow" glow (box shadow that spills outside the
// bounds). Used for the FanConnact logo (pulsing) and team logos (static).
class GlowWrapper extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final bool pulse;
  final double glowBlur;
  final double glowSpread;
  final BorderRadius? borderRadius;

  const GlowWrapper({
    super.key,
    required this.child,
    this.glowColor = AppColors.brandBlue,
    this.pulse = false,
    this.glowBlur = 12,
    this.glowSpread = 2,
    this.borderRadius,
  });

  @override
  State<GlowWrapper> createState() => _GlowWrapperState();
}

class _GlowWrapperState extends State<GlowWrapper>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  Animation<double>? _blur;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);
      _blur = Tween<double>(
        begin: widget.glowBlur * 0.5,
        end: widget.glowBlur * 1.5,
      ).animate(CurvedAnimation(parent: _ctrl!, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blur = widget.pulse
        ? (_blur?.value ?? widget.glowBlur)
        : widget.glowBlur;
    return Container(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: [
          BoxShadow(
            color: widget.glowColor.withValues(alpha: 0.55),
            blurRadius: blur,
            spreadRadius: widget.glowSpread,
          ),
        ],
      ),
      child: widget.child,
    );
  }
}
