import 'dart:async';
import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../services/live_match_service.dart';
import '../services/match_chat_service.dart';
import '../widgets/glow_wrapper.dart';
import '../widgets/match_games.dart';

// Crex-style match center: opens when a match is tapped. Shows a live
// scorecard header + tabbed sections (Info, Live Chat, Summary/Graph,
// Series Stats, Games). Live scores auto-refresh; chat is real-time WS.
class MatchDetailScreen extends StatefulWidget {
  final MatchItem match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late MatchItem _match;
  Timer? _timer;
  bool _loading = false;

  late TabController _tabController;
  final List<String> _tabs = const [
    'Info',
    'Live Chat',
    'Summary',
    'Series',
    'Games',
  ];

  MatchChatService? _chat;

  // Poll every 3s for live matches so scores feel real-time (the backend
  // cache is now 20s, so this stays well within quota while feeling snappy).
  static const Duration _poll = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _tabController = TabController(length: _tabs.length, vsync: this);
    _startPolling();
    _initChat();
  }

  void _initChat() {
    if (_match.matchId == null) return;
    _chat = MatchChatService(matchId: _match.matchId!);
    _chat!.connect();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _chat?.dispose();
    super.dispose();
  }

  void _startPolling() {
    if (_match.matchId == null) return;
    _refresh();
    _timer = Timer.periodic(_poll, (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_match.matchId == null) return;
    if (mounted) setState(() => _loading = true);
    final updated = await LiveMatchService.fetchMatchDetail(
      matchId: _match.matchId!,
      sport: _match.sport,
    );
    if (mounted) {
      setState(() {
        if (updated != null) _match = updated;
        _loading = false;
      });
    }
  }

  Color _statusColor() {
    switch (_match.status) {
      case 'LIVE':
        return AppColors.liveRed;
      case 'UPCOMING':
        return AppColors.upcomingAmber;
      default:
        return AppColors.completedGrey;
    }
  }

  Widget _teamLogo(String? logo, {double size = 52}) {
    if (logo != null && logo.isNotEmpty) {
      return GlowWrapper(
        glowColor: AppColors.brandBlue,
        glowBlur: 12,
        glowSpread: 1,
        borderRadius: BorderRadius.circular(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            logo,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(Icons.sports, size: size * 0.7),
          ),
        ),
      );
    }
    return Icon(Icons.sports, size: size * 0.7);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final live = _match.status == 'LIVE';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          _match.series.isNotEmpty ? _match.series : 'Match Center',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: 'Refresh',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: AppColors.brandBlue,
          indicatorColor: AppColors.brandBlue,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
      body: Column(
        children: [
          _ScoreHeader(
            isDark: isDark,
            match: _match,
            live: live,
            statusColor: _statusColor(),
            teamLogo: _teamLogo,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InfoTab(match: _match, isDark: isDark),
                _ChatTab(chat: _chat, isDark: isDark, match: _match),
                _SummaryTab(match: _match, isDark: isDark),
                _SeriesTab(match: _match, isDark: isDark),
                MatchGames(isDark: isDark, sport: _match.sport),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score header (always visible, like Crex) ─────────────────────────────────
class _ScoreHeader extends StatelessWidget {
  final bool isDark;
  final MatchItem match;
  final bool live;
  final Color statusColor;
  final Widget Function(String?, {double size}) teamLogo;

  const _ScoreHeader({
    required this.isDark,
    required this.match,
    required this.live,
    required this.statusColor,
    required this.teamLogo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
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
          Row(
            children: [
              if (live)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.liveRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.liveRed.withValues(alpha: 0.7),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              Text(
                match.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (match.matchType != null && match.matchType!.isNotEmpty)
                Text(
                  match.matchType!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    teamLogo(match.logoA),
                    const SizedBox(height: 6),
                    Text(match.teamA,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(match.scoreA ?? '-',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const Text('vs', style: TextStyle(color: Colors.grey)),
                  Text(match.scoreB ?? '-',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    teamLogo(match.logoB),
                    const SizedBox(height: 6),
                    Text(match.teamB,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          if (match.result != null && match.result!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                match.result!,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (live)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Auto-updating live • refreshes every 3s',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Info tab (Crex-style cards) ─────────────────────────────────────────────
class _InfoTab extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _InfoTab({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRowData>[];
    if (match.toss != null && match.toss!.isNotEmpty)
      rows.add(_InfoRowData(Icons.flag, 'Toss', match.toss!));
    if (match.venue != null && match.venue!.isNotEmpty)
      rows.add(_InfoRowData(Icons.location_on, 'Venue', match.venue!));
    if (match.time.isNotEmpty)
      rows.add(_InfoRowData(Icons.access_time, 'Time', match.time));
    if (match.series.isNotEmpty)
      rows.add(_InfoRowData(Icons.emoji_events, 'Series', match.series));
    if (match.matchType != null && match.matchType!.isNotEmpty)
      rows.add(_InfoRowData(Icons.sports, 'Format', match.matchType!));

    if (rows.isEmpty) {
      return const Center(
        child: Text('No extra info available for this match.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        for (final r in rows)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(r.icon, color: AppColors.brandBlue, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white54 : Colors.black45,
                            letterSpacing: 0.5,
                          )),
                      const SizedBox(height: 2),
                      Text(r.value,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRowData(this.icon, this.label, this.value);
}

// ── Live Chat tab (real websocket) ───────────────────────────────────────────
class _ChatTab extends StatefulWidget {
  final MatchChatService? chat;
  final bool isDark;
  final MatchItem match;
  const _ChatTab({required this.chat, required this.isDark, required this.match});

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final TextEditingController _ctrl = TextEditingController();
  final List<String> _stickers = const ['🔥', '💪', '👏', '😂', '😮', '🎯'];
  bool _showStickers = false;
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty || widget.chat == null) return;
    widget.chat!.sendText(t);
    _ctrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chat == null) {
      return const Center(child: Text('Chat unavailable for this match.'));
    }
    final chat = widget.chat!;
    return Column(
      children: [
        StreamBuilder<ChatEvent>(
          stream: chat.stream,
          builder: (ctx, snap) {
            final online = chat.onlineCount;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: AppColors.brandBlue.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.green),
                  const SizedBox(width: 6),
                  Text('$online online',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('Live chat • real-time',
                      style: TextStyle(
                          fontSize: 11,
                          color: widget.isDark ? Colors.white54 : Colors.black45)),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: StreamBuilder<ChatEvent>(
            stream: chat.stream,
            builder: (ctx, snap) {
              final msgs = chat.messages;
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: msgs.length,
                itemBuilder: (_, i) =>
                    _ChatBubble(msg: msgs[i], isDark: widget.isDark),
              );
            },
          ),
        ),
        if (_showStickers)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: widget.isDark ? AppColors.darkSurface : Colors.grey.shade100,
            child: Wrap(
              spacing: 10,
              children: _stickers
                  .map((s) => GestureDetector(
                        onTap: () {
                          chat.sendSticker(s);
                          setState(() => _showStickers = false);
                          _scrollToBottom();
                        },
                        child: Text(s, style: const TextStyle(fontSize: 26)),
                      ))
                  .toList(),
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          color: widget.isDark ? AppColors.darkSurface : Colors.grey.shade50,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _showStickers ? Icons.keyboard : Icons.emoji_emotions,
                  color: AppColors.brandBlue,
                ),
                onPressed: () => setState(() => _showStickers = !_showStickers),
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onChanged: (v) => chat.sendTyping(v.isNotEmpty),
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Cheer for your team…',
                    filled: true,
                    fillColor: widget.isDark ? AppColors.darkCard : Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.brandBlue),
                onPressed: _send,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isDark;
  const _ChatBubble({required this.msg, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (msg.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.center,
        child: Text(
          msg.text ?? '',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage:
                msg.userImg != null ? NetworkImage(msg.userImg!) : null,
            child: msg.userImg == null
                ? Text((msg.userName ?? '?').isNotEmpty
                    ? msg.userName![0].toUpperCase()
                    : '?')
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg.userName ?? 'Fan',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 2),
                if (msg.sticker != null)
                  Text(msg.sticker!, style: const TextStyle(fontSize: 28))
                else if (msg.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(msg.image!, height: 120),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.text ?? '',
                        style: const TextStyle(fontSize: 14)),
                  ),
                if (msg.likes > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('❤️ ${msg.likes}',
                        style: const TextStyle(fontSize: 11, color: Colors.red)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary / Scorecard graph tab (sport-aware, Crex-style) ──────────────────
class _SummaryTab extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _SummaryTab({required this.match, required this.isDark});

  bool get _isCricket => (match.sport ?? '').toLowerCase() == 'cricket';

  @override
  Widget build(BuildContext context) {
    final a = _parseScore(match.scoreA);
    final b = _parseScore(match.scoreB);
    final maxV = [a, b, 1].reduce((x, y) => x > y ? x : y).toDouble();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Scorecard header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.brandBlue,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                  child: Text('TEAM',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5))),
              SizedBox(width: 60, child: Center(child: Text('SCORE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)))),
              SizedBox(width: 50, child: Center(child: Text('WKTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)))),
            ],
          ),
        ),
        _ScorecardRow(
          team: match.teamA,
          score: match.scoreA,
          isDark: isDark,
          isFirst: true,
        ),
        _ScorecardRow(
          team: match.teamB,
          score: match.scoreB,
          isDark: isDark,
          isFirst: false,
        ),
        const SizedBox(height: 18),
        const Text('Run comparison',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 12),
        _BarRow(label: match.teamA, value: a, max: maxV, color: AppColors.brandBlue),
        const SizedBox(height: 10),
        _BarRow(label: match.teamB, value: b, max: maxV, color: AppColors.liveRed),
        const SizedBox(height: 18),
        SizedBox(
          height: 160,
          child: CustomPaint(
            size: const Size(double.infinity, 160),
            painter: _ScorePainter(a, b, isDark),
          ),
        ),
        const SizedBox(height: 16),
        if (match.result != null && match.result!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(match.result!,
                style: const TextStyle(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
          ),
      ],
    );
  }

  int _parseScore(String? s) {
    if (s == null || s.isEmpty) return 0;
    final m = RegExp(r'(\d+)').firstMatch(s);
    return m != null ? int.tryParse(m.group(1)!) ?? 0 : 0;
  }
}

class _ScorecardRow extends StatelessWidget {
  final String team;
  final String? score;
  final bool isDark;
  final bool isFirst;
  const _ScorecardRow(
      {required this.team,
      this.score,
      required this.isDark,
      required this.isFirst});

  @override
  Widget build(BuildContext context) {
    final runs = _runs(score);
    final wkts = _wkts(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
          left: BorderSide(color: Colors.grey.withOpacity(0.15)),
          right: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
        borderRadius: isFirst
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              )
            : const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(team,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: Text(runs,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
          SizedBox(
            width: 50,
            child: Center(
              child: Text(wkts,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54)),
            ),
          ),
        ],
      ),
    );
  }

  String _runs(String? s) {
    if (s == null || s.isEmpty) return '—';
    final m = RegExp(r'(\d+)').firstMatch(s);
    return m != null ? m.group(1)! : '—';
  }

  String _wkts(String? s) {
    if (s == null || s.isEmpty) return '—';
    final m = RegExp(r'-(\d+)').firstMatch(s);
    return m != null ? m.group(1)! : '—';
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int value;
  final double max;
  final Color color;
  const _BarRow(
      {required this.label,
      required this.value,
      required this.max,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: max > 0 ? value / max : 0,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 14,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ScorePainter extends CustomPainter {
  final int a;
  final int b;
  final bool isDark;
  _ScorePainter(this.a, this.b, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final maxV = [a, b, 1].reduce((x, y) => x > y ? x : y).toDouble();
    final barW = w / 3;

    paint.color = AppColors.brandBlue;
    final ha = h * (a / maxV) * 0.9;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barW * 0.5, h - ha, barW * 0.6, ha),
        const Radius.circular(6),
      ),
      paint,
    );
    paint.color = AppColors.liveRed;
    final hb = h * (b / maxV) * 0.9;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barW * 1.6, h - hb, barW * 0.6, hb),
        const Radius.circular(6),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ── Series stats tab ─────────────────────────────────────────────────────────
class _SeriesTab extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _SeriesTab({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final series = match.series.isNotEmpty ? match.series : 'This Series';
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.brandBlue, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(series,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('Head-to-head & series standings',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _StatCard(title: '${match.teamA} wins', value: '—', isDark: isDark),
        _StatCard(title: '${match.teamB} wins', value: '—', isDark: isDark),
        _StatCard(title: 'No results', value: '—', isDark: isDark),
        const SizedBox(height: 10),
        Text(
          'Detailed series stats sync from the backend rankings service. '
          'Live match data is powered by cricket-live-line1 / allsportsapi2.',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isDark;
  const _StatCard(
      {required this.title, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.brandBlue)),
        ],
      ),
    );
  }
}
