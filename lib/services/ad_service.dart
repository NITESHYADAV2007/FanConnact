// AdMob wrapper — professional banner + interstitial ads.
// Uses Google's official test unit IDs so builds pass review and show real
// test creatives. Replace with your AdMob app/unit IDs before release.

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _init = false;
  static DateTime _lastInterstitial = DateTime.fromMillisecondsSinceEpoch(0);

  // Test ad unit IDs (Google). Swap for your production IDs.
  static const String bannerUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static InterstitialAd? _interstitial;
  static bool _loadingInterstitial = false;

  static Future<void> init() async {
    if (_init) return;
    try {
      await MobileAds.instance.initialize();
      _init = true;
    } catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  static Widget banner() => const _AdBanner();

  static void _loadInterstitial() {
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (err) {
          _loadingInterstitial = false;
          debugPrint('Interstitial load failed: ${err.message}');
        },
      ),
    );
  }

  /// Shows the interstitial if one is loaded and the min interval passed.
  static Future<void> maybeShowInterstitial({
    Duration minInterval = const Duration(seconds: 90),
  }) async {
    await init();
    if (_interstitial == null) {
      _loadInterstitial();
      return;
    }
    if (DateTime.now().difference(_lastInterstitial) < minInterval) return;
    final ad = _interstitial!;
    _interstitial = null;
    _lastInterstitial = DateTime.now();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => _loadInterstitial(),
      onAdFailedToShowFullScreenContent: (_, __) => _loadInterstitial(),
    );
    ad.show();
  }
}

class _AdBanner extends StatefulWidget {
  const _AdBanner();

  @override
  State<_AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<_AdBanner> {
  BannerAd? _ad;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    AdService.init().then((_) {
      if (!mounted) return;
      final ad = BannerAd(
        adUnitId: AdService.bannerUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (loadedAd) {
            if (mounted) setState(() => _ad = loadedAd as BannerAd);
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('Banner load failed: ${err.message}');
            ad.dispose();
          },
        ),
      );
      ad.load();
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        color: Colors.black.withValues(alpha: 0.03),
        child: Center(
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}