import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n.dart';
import '../data.dart';
import '../services/currents_service.dart';

class NewsScreen extends StatefulWidget {
  final ThemeType themeType;
  final ValueChanged<ThemeType> onThemeChanged;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final Color accentColor;
  final ValueChanged<Color> onAccentColorChanged;

  const NewsScreen({
    super.key,
    required this.themeType,
    required this.onThemeChanged,
    required this.locale,
    required this.onLocaleChanged,
    required this.accentColor,
    required this.onAccentColorChanged,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsItem> _articles = [];
  bool _loading = true;
  String _sport = 'all';
  String _lang = 'en';

  static const _sports = ['all', 'cricket', 'football', 'basketball', 'tennis', 'hockey', 'kabaddi', 'esports', 'baseball', 'volleyball'];
  static const _sportLabels = {'all':'All Sports','cricket':'Cricket','football':'Football','basketball':'Basketball','tennis':'Tennis','hockey':'Hockey','kabaddi':'Kabaddi','esports':'E-Sports','baseball':'Baseball','volleyball':'Volleyball'};
  static const _langs = [{'code':'en','label':'English'},{'code':'hi','label':'हिन्दी'},{'code':'es','label':'Español'},{'code':'fr','label':'Français'},{'code':'ar','label':'العربية'}];

  @override
  void initState() {
    super.initState();
    _lang = widget.locale.languageCode;
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final arts = await CurrentsService.fetchHeadlines(category: _sport, language: _lang);
    if (mounted) setState(() { _articles = arts; _loading = false; });
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening: $url'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeType == ThemeType.dark || widget.themeType == ThemeType.stadium || widget.themeType == ThemeType.esports || widget.themeType == ThemeType.royal || widget.themeType == ThemeType.custom;
    final bg = widget.themeType == ThemeType.custom
        ? Colors.transparent
        : (isDark ? const Color(0xFF0E1116) : const Color(0xFFF4F6FA));
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? const Color(0xFF1C2230) : Colors.white;
    final cfg = themeConfigFor(widget.themeType);

    Widget body = Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(AppStrings.get(widget.locale.languageCode, 'news'), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(widget.themeType == ThemeType.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.onThemeChanged(widget.themeType == ThemeType.dark ? ThemeType.light : ThemeType.dark),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sport filter chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _sports.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final s = _sports[i];
                final sel = _sport == s;
                return ChoiceChip(
                  label: Text(_sportLabels[s] ?? s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  selected: sel,
                  selectedColor: widget.accentColor,
                  labelStyle: TextStyle(color: sel ? Colors.white : null, fontSize: 12),
                  onSelected: (_) { setState(() => _sport = s); _fetch(); },
                );
              },
            ),
          ),
          // Language selector
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _langs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemBuilder: (_, i) {
                final l = _langs[i];
                final sel = _lang == l['code'];
                return GestureDetector(
                  onTap: () { setState(() => _lang = l['code']!); _fetch(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? widget.accentColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: sel ? widget.accentColor : Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: Text(l['label']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Colors.white : textColor)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          // Article list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _articles.isEmpty
                    ? Center(child: Text('No news', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _articles.length,
                        itemBuilder: (_, i) => _buildArticleCard(_articles[i], i, cardBg, textColor, isDark, cfg),
                      ),
          ),
        ],
      ),
    );

    if (cfg.hasBackground) {
      body = Stack(
        children: [
          Positioned.fill(child: ThemeBackground(src: cfg.backgroundAsset!)),
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.45))),
          body,
        ],
      );
    }

    return body;
  }

  Widget _buildArticleCard(NewsItem a, int i, Color cardBg, Color textColor, bool isDark, ThemeConfig cfg) {
    final hasImage = a.image != null && a.image!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _launchUrl(a.link ?? ''),
        child: Container(
          decoration: cfg.glassCards
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                )
              : BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06), blurRadius: 8, offset: const Offset(0, 3))],
                ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                Stack(
                  children: [
                    Image.network(a.image!, height: 180, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    Container(
                      height: 180,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87]),
                      ),
                    ),
                    Positioned(
                      bottom: 10, left: 12, right: 12,
                      child: Text(a.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              if (!hasImage)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textColor)),
                    if (a.description != null && a.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(a.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                    ],
                  ]),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  children: [
                    Text(a.source, style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600)),
                    const Spacer(),
                    Icon(Icons.arrow_forward, size: 14, color: widget.accentColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
