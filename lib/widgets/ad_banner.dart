import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/feature_gate.dart';

/// Banner publicitario de AdMob.
///
/// Se oculta automáticamente si el usuario tiene plan Pro o superior.
/// Usa IDs de prueba de Google por defecto.
/// Cuando tengas cuenta AdMob real, reemplazá [_adUnitId] con tu Unit ID.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  // ID de prueba oficial de Google — reemplazar con ID real al publicar
  static const String _adUnitId = 'ca-app-pub-3940256099942544/6300978111';

  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // No cargar ad si el usuario paga
    if (FeatureGate.showAds) {
      _load();
    }
  }

  void _load() {
    _ad = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureGate.showAds) return const SizedBox.shrink();
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
