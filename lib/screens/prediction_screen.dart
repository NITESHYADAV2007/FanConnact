import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../l10n.dart';
import '../data.dart';
import '../services/live_match_service.dart';

// Predictions — mirrors the web prediction.html (pick a winner, earn coins).
class PredictionScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;

  const PredictionScreen({super.key, required this.locale, required this.isDark});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  List<MatchItem> _matches = [];
  bool _loading = true;
  final Map<String, String> _picks = {}; // matchId -> picked team name
  int _coins = 100;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await LiveMatchService.fetchLiveMatches(sport: 'all');
      // Only upcoming matches are predictable.
      final upcoming = all.where((m) => m.status != 'LIVE').toList();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        _coins = int.tryParse('${snap.data()?['coins'] ?? 100}') ?? 100;
      }
      setState(() {
        _matches = upcoming;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitPick(MatchItem m, String team) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || m.matchId == null) return;
    setState(() => _picks[m.matchId!] = team);
    // Award coins and record the prediction in Firestore.
    final ref =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    await FirebaseFirestore.instance
        .collection('predictions')
        .doc('${user.uid}_${m.matchId}')
        .set({
      'uid': user.uid,
      'matchId': m.matchId,
      'teamA': m.teamA,
      'teamB': m.teamB,
      'pick': team,
      'status': m.status,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Give a small coin reward for engaging (mirrors web behavior).
    await ref.set({'coins': FieldValue.increment(5)},
        SetOptions(merge: true));
    setState(() => _coins += 5);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pick saved: $team  (+5 🪙)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Predictions',
            style: TextStyle(fontWeight: FontWeight.w800)),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$_coins 🪙',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandBlue)),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
              ? const Center(child: Text('No upcoming matches to predict'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _matches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final m = _matches[i];
                    final picked = _picks[m.matchId];
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.grey.withOpacity(0.15)),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (m.series.isNotEmpty)
                            Text(m.series,
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 12)),
                          const SizedBox(height: 8),
                          _teamRow(m, m.teamA, m.logoA, picked, isDark),
                          const SizedBox(height: 8),
                          _teamRow(m, m.teamB, m.logoB, picked, isDark),
                          const SizedBox(height: 8),
                          Text(
                              picked != null
                                  ? 'Your pick: $picked'
                                  : 'Pick a winner to earn coins',
                              style: TextStyle(
                                  color: picked != null
                                      ? AppColors.brandBlue
                                      : Colors.grey.shade500,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _teamRow(MatchItem m, String name, String? logo, String? picked,
      bool isDark) {
    final selected = picked == name;
    return GestureDetector(
      onTap: picked == null ? () => _submitPick(m, name) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandBlue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.brandBlue
                : Colors.grey.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            if (logo != null && logo.isNotEmpty)
              Image.network(logo, height: 26, width: 26,
                  errorBuilder: (_, __, ___) => const Icon(Icons.sports, size: 22))
            else
              const Icon(Icons.sports, size: 22),
            const SizedBox(width: 10),
            Expanded(
                child: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.brandBlue),
          ],
        ),
      ),
    );
  }
}
