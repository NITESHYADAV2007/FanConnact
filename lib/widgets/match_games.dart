import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';

// Lightweight, genuinely playable mini-games shown under the match center.
// These run fully on-device (no backend) so they work in testing / offline.

class MatchGames extends StatefulWidget {
  final bool isDark;
  final String? sport;
  const MatchGames({super.key, required this.isDark, this.sport});

  @override
  State<MatchGames> createState() => _MatchGamesState();
}

class _MatchGamesState extends State<MatchGames> {
  int _selected = 0;

  String get _sportLabel {
    final s = (widget.sport ?? '').toLowerCase();
    if (s == 'cricket') return 'Cricket';
    if (s == 'football') return 'Football';
    if (s == 'basketball') return 'Basketball';
    if (s == 'baseball') return 'Baseball';
    return 'Match';
  }

  final List<_GameMeta> _games = const [
    _GameMeta(key: 'tap', name: 'Tap Race', emoji: '⚡', desc: 'Tap fast in 10s'),
    _GameMeta(key: 'coin', name: 'Odd / Even', emoji: '🪙', desc: 'Guess the coin'),
    _GameMeta(key: 'memory', name: 'Memory Flip', emoji: '🃏', desc: 'Match the pairs'),
  ];

  @override
  Widget build(BuildContext context) {
    final card = widget.isDark ? AppColors.darkCard : Colors.white;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_esports, color: AppColors.brandBlue, size: 18),
              const SizedBox(width: 8),
              Text('Play & Win · $_sportLabel',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('FanCoins',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _games.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final g = _games[i];
                final active = i == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.brandBlue.withValues(alpha: 0.14)
                          : Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? AppColors.brandBlue : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(g.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(g.desc,
                            style: TextStyle(
                                fontSize: 10,
                                color: widget.isDark
                                    ? Colors.white60
                                    : Colors.black54)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildGame(),
        ],
      ),
    );
  }

  Widget _buildGame() {
    switch (_games[_selected].key) {
      case 'coin':
        return _CoinGame(isDark: widget.isDark);
      case 'memory':
        return _MemoryGame(isDark: widget.isDark);
      default:
        return _TapGame(isDark: widget.isDark);
    }
  }
}

class _GameMeta {
  final String key;
  final String name;
  final String emoji;
  final String desc;
  const _GameMeta({
    required this.key,
    required this.name,
    required this.emoji,
    required this.desc,
  });
}

// ── Tap Race ────────────────────────────────────────────────────────────────
class _TapGame extends StatefulWidget {
  final bool isDark;
  const _TapGame({required this.isDark});
  @override
  State<_TapGame> createState() => _TapGameState();
}

class _TapGameState extends State<_TapGame> {
  int _taps = 0;
  int _timeLeft = 10;
  bool _running = false;
  Timer? _timer;

  void _start() {
    setState(() {
      _taps = 0;
      _timeLeft = 10;
      _running = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        setState(() => _running = false);
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_running ? 'Time left: $_timeLeft s' : 'Tap as fast as you can!',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _running
                  ? () => setState(() => _taps++)
                  : _start,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              child: Text(_running ? 'TAP ($_taps)' : 'START'),
            ),
          ],
        ),
        if (!_running && _taps > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Score: $_taps taps • +${_taps ~/ 5} FanCoins',
                style: TextStyle(
                    color: AppColors.brandBlue, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

// ── Odd / Even Coin ──────────────────────────────────────────────────────────
class _CoinGame extends StatefulWidget {
  final bool isDark;
  const _CoinGame({required this.isDark});
  @override
  State<_CoinGame> createState() => _CoinGameState();
}

class _CoinGameState extends State<_CoinGame> {
  int? _roll;
  String? _guess;
  String? _result;

  void _flip() {
    if (_guess == null) {
      setState(() => _result = 'Pick Odd or Even first!');
      return;
    }
    final r = Random().nextInt(6) + 1; // 1..6
    final even = r % 2 == 0;
    final win = (_guess == 'even' && even) || (_guess == 'odd' && !even);
    setState(() {
      _roll = r;
      _result = win ? 'You won! 🎉 +5 FanCoins' : 'You lost 😅';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Choice('odd', 'Odd', Icons.looks_one),
            const SizedBox(width: 12),
            _Choice('even', 'Even', Icons.looks_two),
          ],
        ),
        const SizedBox(height: 10),
        Text(_roll == null ? 'Roll: -' : 'Roll: $_roll',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _flip,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('ROLL DICE'),
        ),
        if (_result != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_result!,
                style: TextStyle(
                    color: AppColors.brandBlue, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _Choice(String value, String label, IconData icon) {
    final active = _guess == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      selected: active,
      onSelected: (_) => setState(() => _guess = value),
      selectedColor: AppColors.brandBlue.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: active ? AppColors.brandBlue : null,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Memory Flip ──────────────────────────────────────────────────────────────
class _MemoryGame extends StatefulWidget {
  final bool isDark;
  const _MemoryGame({required this.isDark});
  @override
  State<_MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<_MemoryGame> {
  late List<_Card> _cards;
  int? _first;
  int? _second;
  int _matched = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final emojis = ['🏏', '⚽', '🏀', '🎾', '🏑', '🎯'];
    final deck = [...emojis, ...emojis];
    deck.shuffle(Random());
    _cards = deck.asMap().entries.map((e) => _Card(e.value, e.key)).toList();
    _first = _second = null;
    _matched = 0;
    _busy = false;
  }

  void _tap(int i) {
    if (_busy || _cards[i].matched || _cards[i].faceUp) return;
    setState(() => _cards[i].faceUp = true);
    if (_first == null) {
      _first = i;
    } else if (_second == null && i != _first) {
      _second = i;
      _busy = true;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (_cards[_first!].emoji == _cards[_second!].emoji) {
          setState(() {
            _cards[_first!].matched = true;
            _cards[_second!].matched = true;
            _matched += 2;
          });
        } else {
          setState(() {
            _cards[_first!].faceUp = false;
            _cards[_second!].faceUp = false;
          });
        }
        _first = _second = null;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Matched: $_matched / ${_cards.length}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            TextButton(onPressed: () => setState(_reset), child: const Text('Reset')),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _cards.length,
          itemBuilder: (_, i) {
            final c = _cards[i];
            return GestureDetector(
              onTap: () => _tap(i),
              child: Container(
                decoration: BoxDecoration(
                  color: c.matched
                      ? AppColors.brandBlue.withValues(alpha: 0.25)
                      : c.faceUp
                          ? AppColors.brandBlue.withValues(alpha: 0.15)
                          : Colors.grey.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.brandBlue.withOpacity(0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  c.faceUp || c.matched ? c.emoji : '?',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            );
          },
        ),
        if (_matched == _cards.length)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Solved! +10 FanCoins 🎉',
                style: TextStyle(
                    color: AppColors.brandBlue, fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }
}

class _Card {
  final String emoji;
  final int index;
  bool faceUp;
  bool matched;
  _Card(this.emoji, this.index)
      : faceUp = false,
        matched = false;
}
