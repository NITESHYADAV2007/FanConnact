import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';
import '../models/prediction_models.dart';
import '../models/prediction_enums.dart';
import '../services/live_match_service.dart';
import '../theme.dart';
import '../data.dart';

class PredictionGameScreen extends StatefulWidget {
  final PredictionGame game;
  final int currentCoins;
  final ValueChanged<int> onCoinsChanged;

  const PredictionGameScreen({
    super.key,
    required this.game,
    required this.currentCoins,
    required this.onCoinsChanged,
  });

  @override
  State<PredictionGameScreen> createState() => _PredictionGameScreenState();
}

class _PredictionGameScreenState extends State<PredictionGameScreen> with SingleTickerProviderStateMixin {
  late TabController _marketTabController;
  String? _selectedMarketId;
  String? _selectedOptionId;
  int _stake = 10;
  Timer? _oddsTimer;
  Timer? _detailTimer;
  final Map<String, List<PredictionOption>> _liveOdds = {};
  String? _liveScoreA;
  String? _liveScoreB;

  @override
  void initState() {
    super.initState();
    _marketTabController = TabController(length: widget.game.markets.length, vsync: this);
    if (widget.game.markets.isNotEmpty) {
      _selectedMarketId = widget.game.markets.first.id;
      _liveScoreA = widget.game.scoreA;
      _liveScoreB = widget.game.scoreB;
    }
    _startOddsSimulation();
    if (widget.game.isLive && widget.game.sportKey == 'cricket') {
      _refreshLiveDetail();
      _detailTimer = Timer.periodic(const Duration(seconds: 20), (_) => _refreshLiveDetail());
    }
  }

  @override
  void dispose() {
    _marketTabController.dispose();
    _oddsTimer?.cancel();
    _detailTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLiveDetail() async {
    if (!widget.game.isLive || widget.game.sportKey != 'cricket') return;
    try {
      final detail = await LiveMatchService.fetchMatchDetail(matchId: widget.game.id, sport: 'cricket');
      if (detail == null || !mounted) return;
      setState(() {
        _liveScoreA = detail.scoreA ?? _liveScoreA;
        _liveScoreB = detail.scoreB ?? _liveScoreB;
      });
    } catch (_) {}
  }

  void _startOddsSimulation() {
    _oddsTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      setState(() {
        for (final market in widget.game.markets) {
          if (!_liveOdds.containsKey(market.id)) {
            _liveOdds[market.id] = market.options.map((o) => PredictionOption(
              id: o.id,
              label: o.label,
              odds: o.odds,
              probability: o.probability,
              totalPicks: o.totalPicks,
              isCorrect: o.isCorrect,
            )).toList();
          }
          
          final opts = _liveOdds[market.id]!;
          for (int i = 0; i < opts.length; i++) {
            final o = opts[i];
            final change = (Random().nextDouble() - 0.5) * 0.08;
            final newOdds = (o.odds + change).clamp(1.01, 20.0);
            final newProb = (1 / newOdds * 0.95).clamp(0.01, 0.99);
            final pickChange = Random().nextInt(10) - 3;
            opts[i] = PredictionOption(
              id: o.id,
              label: o.label,
              odds: newOdds,
              probability: newProb,
              totalPicks: (o.totalPicks + pickChange).clamp(0, 99999),
              isCorrect: o.isCorrect,
            );
          }
        }
      });
    });
  }

  int get _potentialWin => (_stake * (_getSelectedOption()?.odds ?? 1.0)).floor();

  PredictionOption? _getSelectedOption() {
    if (_selectedMarketId == null || _selectedOptionId == null) return null;
    final market = widget.game.markets.firstWhere((m) => m.id == _selectedMarketId);
    return market.getSelectedOption(_selectedOptionId);
  }

  Future<void> _placePrediction() async {
    if (_selectedMarketId == null || _selectedOptionId == null) return;
    if (_stake > widget.currentCoins) {
      _showError('Insufficient coins');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final market = widget.game.markets.firstWhere((m) => m.id == _selectedMarketId);
    final option = market.getSelectedOption(_selectedOptionId)!;

    setState(() => _stake = _stake); // trigger rebuild for loading

    try {
      final predId = '${user.uid}_${widget.game.id}_$_selectedMarketId';
      
      await FirebaseFirestore.instance.collection('predictions').doc(predId).set({
        'id': predId,
        'uid': user.uid,
        'userId': user.uid,
        'gameId': widget.game.id,
        'marketId': _selectedMarketId,
        'optionId': _selectedOptionId,
        'optionLabel': option.label,
        'oddsAtPick': option.odds,
        'coinsStaked': _stake,
        'potentialWin': _potentialWin,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'coins': FieldValue.increment(-_stake),
      }, SetOptions(merge: true));

      widget.onCoinsChanged(widget.currentCoins - _stake);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Prediction placed! ${_potentialWin - _stake} potential profit'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _selectedOptionId = null;
          _stake = 10;
        });
      }
    } catch (e) {
      _showError('Failed to place prediction: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sportMeta = sports.firstWhere((s) => s.key == widget.game.sportKey, orElse: () => sports.firstWhere((s) => s.key == 'cricket'));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.game.teamA} vs ${widget.game.teamB}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        automaticallyImplyLeading: true,
        bottom: widget.game.markets.length > 1
            ? TabBar(
                controller: _marketTabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.brandBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                onTap: (i) => setState(() {
                  _selectedMarketId = widget.game.markets[i].id;
                  _selectedOptionId = null;
                }),
                tabs: widget.game.markets.map((m) => Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(m.question, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                )).toList(),
              )
            : null,
      ),
      body: Column(
        children: [
          // Header with match info
          _MatchHeader(
            game: widget.game,
            sportMeta: sportMeta,
            isDark: isDark,
            liveScoreA: _liveScoreA,
            liveScoreB: _liveScoreB,
          ),
          
          // Markets content
          Expanded(
            child: widget.game.markets.isEmpty
                ? _EmptyContent(isDark: isDark)
                : TabBarView(
                    controller: _marketTabController,
                    children: widget.game.markets.map((market) {
                      final liveOpts = _liveOdds[market.id] ?? market.options;
                      return _MarketView(
                        game: widget.game,
                        market: market,
                        liveOptions: liveOpts,
                        selectedOptionId: _selectedOptionId,
                        onOptionTap: (optId) => setState(() {
                          _selectedOptionId = optId;
                          _selectedMarketId = market.id;
                        }),
                        isDark: isDark,
                      );
                    }).toList(),
                  ),
          ),
          
          // Sticky stake bar
          if (_selectedOptionId != null) _StakeBar(
            stake: _stake,
            onStakeChanged: (v) => setState(() => _stake = v),
            potentialWin: _potentialWin,
            availableCoins: widget.currentCoins,
            onPlace: _placePrediction,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _MatchHeader extends StatelessWidget {
  final PredictionGame game;
  final Sport sportMeta;
  final bool isDark;
  final String? liveScoreA;
  final String? liveScoreB;

  const _MatchHeader({
    required this.game,
    required this.sportMeta,
    required this.isDark,
    this.liveScoreA,
    this.liveScoreB,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            game.isLive ? AppColors.liveRed.withValues(alpha: 0.15) : AppColors.brandBlue.withValues(alpha: 0.12),
            game.isLive ? AppColors.liveRed.withValues(alpha: 0.05) : AppColors.brandBlue.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: game.isLive ? AppColors.liveRed : AppColors.brandBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (game.isLive)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      game.isLive ? 'LIVE' : sportMeta.emoji,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (game.series?.isNotEmpty ?? false)
                Expanded(
                  child: Text(
                    game.series!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (game.isTrending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 12, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('TRENDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.amber)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TeamBadgeLarge(name: game.teamA, logo: game.logoA, isDark: isDark),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${game.teamA} vs ${game.teamB}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            game.venue,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (!game.isLive)
                      Text(
                        'Starts ${_formatDateTime(game.startTime)}',
                        style: TextStyle(fontSize: 11, color: AppColors.brandBlue, fontWeight: FontWeight.w600),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.liveRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('MATCH IN PROGRESS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    if (game.isLive && liveScoreA != null && liveScoreB != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$liveScoreA    :    $liveScoreB',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.liveRed),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _TeamBadgeLarge(name: game.teamB, logo: game.logoB, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
  }
}

class _TeamBadgeLarge extends StatelessWidget {
  final String name;
  final String? logo;
  final bool isDark;

  const _TeamBadgeLarge({required this.name, this.logo, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
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
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.brandBlue),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MarketView extends StatelessWidget {
  final PredictionGame game;
  final PredictionMarket market;
  final List<PredictionOption> liveOptions;
  final String? selectedOptionId;
  final ValueChanged<String> onOptionTap;
  final bool isDark;

  const _MarketView({
    required this.game,
    required this.market,
    required this.liveOptions,
    required this.selectedOptionId,
    required this.onOptionTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Question header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getMarketIcon(market.type), color: AppColors.brandBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      market.question,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${liveOptions.fold<int>(0, (sum, o) => sum + o.totalPicks)} total predictions',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Options grid
        ...liveOptions.map((opt) => _OptionCard(
          option: opt,
          isSelected: selectedOptionId == opt.id,
          onTap: () => onOptionTap(opt.id),
          isDark: isDark,
        )),
        
        const SizedBox(height: 24),
        
        // Market stats
        _MarketStatsBar(options: liveOptions, isDark: isDark),
        
        const SizedBox(height: 100), // Space for stake bar
      ],
    );
  }

  IconData _getMarketIcon(MarketType type) {
    switch (type) {
      case MarketType.winner: return Icons.emoji_events_outlined;
      case MarketType.toss: return Icons.monetization_on_outlined;
      case MarketType.topBatter: return Icons.sports_cricket_outlined;
      case MarketType.topBowler: return Icons.sports_cricket_outlined;
      case MarketType.powerplayRuns: return Icons.flash_on_outlined;
      case MarketType.totalSixes: return Icons.format_list_numbered_outlined;
      case MarketType.methodDismissal: return Icons.sports_outlined;
      case MarketType.overUnder: return Icons.remove_outlined;
      case MarketType.playerPerformance: return Icons.person_outline;
      default: return Icons.help_outline;
    }
  }
}

class _OptionCard extends StatelessWidget {
  final PredictionOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.brandBlue.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.brandBlue : Colors.grey.withValues(alpha: 0.12),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: AppColors.brandBlue.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Row(
          children: [
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.brandBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.brandBlue : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Option info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isSelected ? AppColors.brandBlue : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          option.formattedOdds,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.brandBlue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          option.formattedProbability,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Popularity bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${option.totalPicks}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: option.probability,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandBlue),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketStatsBar extends StatelessWidget {
  final List<PredictionOption> options;
  final bool isDark;

  const _MarketStatsBar({required this.options, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = options.fold<int>(0, (sum, o) => sum + o.totalPicks);
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Market Sentiment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: options.map((opt) {
              final pct = total > 0 ? opt.totalPicks / total : 0.0;
              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt.label,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('${(pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandBlue)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandBlue.withValues(alpha: 0.7)),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StakeBar extends StatelessWidget {
  final int stake;
  final ValueChanged<int> onStakeChanged;
  final int potentialWin;
  final int availableCoins;
  final VoidCallback onPlace;
  final bool isDark;

  const _StakeBar({
    required this.stake,
    required this.onStakeChanged,
    required this.potentialWin,
    required this.availableCoins,
    required this.onPlace,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final profit = potentialWin - stake;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Potential Return', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      Text('$potentialWin 🪙', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.brandBlue)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Profit', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      Text(
                        profit > 0 ? '+$profit 🪙' : '$profit 🪙',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: profit > 0 ? Colors.green : Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Stake slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Stake: $stake 🪙', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('Available: $availableCoins 🪙', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: stake > 10 ? () => onStakeChanged(stake - 10) : null,
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.brandBlue),
                      style: IconButton.styleFrom(backgroundColor: AppColors.brandBlue.withValues(alpha: 0.1)),
                    ),
                    Expanded(
                      child: Slider(
                        value: stake.toDouble(),
                        min: 10,
                        max: availableCoins.toDouble(),
                        divisions: ((availableCoins - 10) / 10).clamp(1, 50).toInt(),
                        label: '$stake',
                        activeColor: AppColors.brandBlue,
                        onChanged: (v) => onStakeChanged(v.round()),
                      ),
                    ),
                    IconButton(
                      onPressed: stake < availableCoins ? () => onStakeChanged(stake + 10) : null,
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.brandBlue),
                      style: IconButton.styleFrom(backgroundColor: AppColors.brandBlue.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Quick stake buttons
            Row(
              children: [
                _QuickStakeBtn(label: '10', onTap: () => onStakeChanged(10), isDark: isDark),
                const SizedBox(width: 8),
                _QuickStakeBtn(label: '50', onTap: () => onStakeChanged(50.clamp(10, availableCoins)), isDark: isDark),
                const SizedBox(width: 8),
                _QuickStakeBtn(label: '100', onTap: () => onStakeChanged(100.clamp(10, availableCoins)), isDark: isDark),
                const SizedBox(width: 8),
                _QuickStakeBtn(label: 'MAX', onTap: () => onStakeChanged(availableCoins), isDark: isDark),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Place bet button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: stake > availableCoins ? null : onPlace,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.casino_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'PLACE PREDICTION • $stake 🪙',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStakeBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickStakeBtn({required this.label, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.brandBlue),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  final bool isDark;

  const _EmptyContent({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No Markets Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Predictions will appear here when markets open', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}