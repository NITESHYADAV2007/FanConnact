import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/prediction_models.dart';
import '../models/prediction_enums.dart';
import '../services/prediction_service.dart';
import '../services/live_match_service.dart';
import '../data.dart';
import '../theme.dart';
import 'prediction_game_screen.dart';

class PredictionScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;

  const PredictionScreen({super.key, required this.locale, required this.isDark});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PredictionGame> _allGames = [];
  List<UserPrediction> _myPredictions = [];
  bool _loading = true;
  int _coins = 100;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
    _autoRefresh = Timer.periodic(const Duration(seconds: 45), (_) => _refreshLight());
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final matches = await LiveMatchService.fetchLiveMatches(sport: 'all');
      final games = PredictionService.generateGamesFromMatches(matches);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await PredictionService.resolveDuePredictions(user.uid);
        await _loadUserData();
      }

      setState(() {
        _allGames = games;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userSnap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final coins = int.tryParse('${userSnap.data()?['coins'] ?? 100}') ?? 100;

    final predsSnap = await FirebaseFirestore.instance
        .collection('predictions')
        .where('uid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    final myPredictions = <UserPrediction>[];
    for (final d in predsSnap.docs) {
      try {
        myPredictions.add(UserPrediction.fromJson(d.data()));
      } catch (_) {}
    }

    if (mounted) setState(() {
      _coins = coins;
      _myPredictions = myPredictions;
    });
  }

  Future<void> _refreshLight() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await PredictionService.resolveDuePredictions(user.uid);
      await _loadUserData();
    } catch (_) {}
  }

  List<PredictionGame> get _liveGames => PredictionService.getLiveGames(_allGames);
  List<PredictionGame> get _trendingGames => PredictionService.getTrendingGames(_allGames);
  List<PredictionGame> get _upcomingGames => PredictionService.getUpcomingGames(_allGames);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Predictions', style: TextStyle(fontWeight: FontWeight.w900)),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: AppColors.brandBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          tabs: const [
            Tab(text: '🔴 LIVE'),
            Tab(text: '🔥 TRENDING'),
            Tab(text: '📅 UPCOMING'),
            Tab(text: '👤 MY PICKS'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, size: 16, color: AppColors.brandBlue),
                    const SizedBox(width: 4),
                    Text('$_coins', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brandBlue)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGamesList(_liveGames, isLive: true),
                _buildGamesList(_trendingGames),
                _buildGamesList(_upcomingGames),
                _buildMyPredictions(),
              ],
            ),
    );
  }

  Widget _buildGamesList(List<PredictionGame> games, {bool isLive = false}) {
    if (games.isEmpty) {
      return _EmptyState(
        icon: isLive ? Icons.live_tv_outlined : Icons.emoji_events_outlined,
        title: isLive ? 'No Live Matches' : 'No Trending Predictions',
        subtitle: isLive 
            ? 'Check back when matches go live'
            : 'Predictions will appear here when available',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: games.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _GameCard(
        game: games[i],
        isLive: isLive,
        onTap: () => _openGameDetail(games[i]),
      ),
    );
  }

  Widget _buildMyPredictions() {
    if (_myPredictions.isEmpty) {
      return _EmptyState(
        icon: Icons.history_outlined,
        title: 'No Predictions Yet',
        subtitle: 'Your active and past picks will appear here',
        actionText: 'Explore Live Games',
        onAction: () => _tabController.animateTo(0),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _myPredictions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final pred = _myPredictions[i];
        final game = _allGames.firstWhere(
          (g) => g.id == pred.gameId,
          orElse: () => PredictionGame(
            id: pred.gameId,
            sportKey: 'cricket',
            teamA: 'Team A',
            teamB: 'Team B',
            venue: '',
            startTime: DateTime.now(),
            status: 'completed',
            markets: [],
          ),
        );
        final market = game.markets.firstWhere(
          (m) => m.id == pred.marketId,
          orElse: () => PredictionMarket(
            id: pred.marketId,
            gameId: pred.gameId,
            question: 'Prediction',
            type: MarketType.winner,
            options: [],
          ),
        );
        final option = market.getSelectedOption(pred.optionId);

        return _MyPredictionCard(
          prediction: pred,
          game: game,
          market: market,
          option: option,
        );
      },
    );
  }

  void _openGameDetail(PredictionGame game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PredictionGameScreen(
          game: game,
          currentCoins: _coins,
          onCoinsChanged: (newCoins) => setState(() => _coins = newCoins),
        ),
      ),
    ).then((_) => _load());
  }
}

class _GameCard extends StatelessWidget {
  final PredictionGame game;
  final bool isLive;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.isLive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sportMeta = sports.firstWhere((s) => s.key == game.sportKey, orElse: () => sports.first);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sport, series, live badge
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              decoration: BoxDecoration(
                color: isLive 
                    ? AppColors.liveRed.withValues(alpha: 0.1)
                    : AppColors.brandBlue.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLive ? AppColors.liveRed : AppColors.brandBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLive) 
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        const SizedBox(width: 4),
                        Text(
                          isLive ? 'LIVE' : sportMeta.emoji,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (game.series?.isNotEmpty ?? false)
                    Expanded(
                      child: Text(
                        game.series!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (game.isTrending)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up, size: 10, color: Colors.amber),
                          SizedBox(width: 2),
                          Text('TRENDING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.amber)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Teams and venue
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _TeamBadge(name: game.teamA, logo: game.logoA, isDark: isDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${game.teamA} vs ${game.teamB}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    game.venue,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _TeamBadge(name: game.teamB, logo: game.logoB, isDark: isDark),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Quick odds preview
                  if (game.markets.isNotEmpty) ...[
                    _QuickOddsRow(markets: game.markets.take(3).toList(), isDark: isDark),
                    const SizedBox(height: 8),
                  ],
                  
                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.people_outline,
                        label: '${game.totalPredictions}',
                        text: 'predictions',
                        color: AppColors.brandBlue,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.timer_outlined,
                        label: _formatTimeUntil(game.startTime),
                        text: game.isLive ? 'elapsed' : 'to start',
                        color: game.isLive ? AppColors.liveRed : Colors.grey,
                        isDark: isDark,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'VIEW MARKETS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeUntil(DateTime startTime) {
    final now = DateTime.now();
    final diff = startTime.difference(now);
    if (diff.isNegative) return 'LIVE';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }
}

class _QuickOddsRow extends StatelessWidget {
  final List<PredictionMarket> markets;
  final bool isDark;

  const _QuickOddsRow({required this.markets, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: markets.map((m) {
        final winnerOpt = m.options.where((o) => o.probability == m.options.map((e) => e.probability).reduce((a, b) => a > b ? a : b)).firstOrNull;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.question,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (winnerOpt != null)
                  Text(
                    '${winnerOpt.label} ${winnerOpt.formattedOdds}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brandBlue),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: color)),
            Text(text, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          ],
        ),
      ],
    );
  }
}

class _TeamBadge extends StatelessWidget {
  final String name;
  final String? logo;
  final bool isDark;

  const _TeamBadge({required this.name, this.logo, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            image: logo != null && logo!.isNotEmpty
                ? DecorationImage(image: NetworkImage(logo!), fit: BoxFit.cover, onError: (_, __) {})
                : null,
          ),
          child: logo == null || logo!.isEmpty
              ? Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.brandBlue),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 56,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MyPredictionCard extends StatelessWidget {
  final UserPrediction prediction;
  final PredictionGame game;
  final PredictionMarket market;
  final PredictionOption? option;

  const _MyPredictionCard({
    required this.prediction,
    required this.game,
    required this.market,
    this.option,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (prediction.status) {
      case PredictionStatus.won:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'WON +${prediction.potentialWin} 🪙';
        break;
      case PredictionStatus.lost:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'LOST -${prediction.coinsStaked} 🪙';
        break;
      case PredictionStatus.pending:
        statusColor = AppColors.brandBlue;
        statusIcon = Icons.hourglass_empty;
        statusText = 'PENDING';
        break;
      case PredictionStatus.cashout:
        statusColor = Colors.orange;
        statusIcon = Icons.sell_outlined;
        statusText = 'CASHED OUT +${prediction.potentialWin} 🪙';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'VOID';
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 6),
              Text(statusText, style: TextStyle(fontWeight: FontWeight.w800, color: statusColor, fontSize: 13)),
              const Spacer(),
              Text(
                '${prediction.coinsStaked} 🪙 @ ${prediction.oddsAtPick.toStringAsFixed(2)}x',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${game.teamA} vs ${game.teamB}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            market.question,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (option != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Your Pick: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text(option!.label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: statusColor)),
                  const SizedBox(width: 6),
                  Text('(${option!.formattedOdds})', style: TextStyle(fontSize: 11, color: statusColor.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(actionText!, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}