// TeamLogo — loads a team/player logo; when the URL is missing or broken it
// falls back to a Wikipedia lead image (keyless), then to initials.

import 'package:flutter/material.dart';
import '../services/wikipedia_service.dart';

class TeamLogo extends StatefulWidget {
  final String name;
  final String? url;
  final double size;
  final double radius;
  final bool round;
  final IconData fallbackIcon;

  const TeamLogo({
    super.key,
    required this.name,
    this.url,
    this.size = 32,
    this.radius = 8,
    this.round = false,
    this.fallbackIcon = Icons.sports,
  });

  @override
  State<TeamLogo> createState() => _TeamLogoState();
}

class _TeamLogoState extends State<TeamLogo> {
  String? _wikiUrl;
  bool _tried = false;

  String? get _effectiveUrl => (widget.url != null && widget.url!.isNotEmpty)
      ? widget.url
      : _wikiUrl;

  @override
  void didUpdateWidget(covariant TeamLogo old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.name != widget.name) {
      _tried = false;
      _wikiUrl = null;
    }
  }

  void _tryWikipedia() {
    if (_tried) return;
    _tried = true;
    WikipediaService.fetchImage(widget.name).then((u) {
      if (mounted && u != null) setState(() => _wikiUrl = u);
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = _effectiveUrl;
    final size = widget.size;
    final radius = widget.radius;
    final initials = widget.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    Widget child;
    if (url != null) {
      child = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          _tryWikipedia();
          return _initialsBox(initials, size);
        },
      );
    } else {
      _tryWikipedia();
      child = _initialsBox(initials, size);
    }

    if (widget.round) {
      return ClipOval(
        child: Container(width: size, height: size, color: Colors.grey.withValues(alpha: 0.15), child: child),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: Colors.grey.withValues(alpha: 0.12),
        child: child,
      ),
    );
  }

  Widget _initialsBox(String initials, double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.34,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade600,
              ),
            )
          : Icon(widget.fallbackIcon, size: size * 0.6, color: Colors.grey.shade500),
    );
  }
}