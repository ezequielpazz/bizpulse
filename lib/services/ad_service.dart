import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Servicio centralizado de ads (interstitial + rewarded).
/// Todos los IDs son de prueba de Google — reemplazar al tener cuenta real.
class AdService {
  static final AdService _i = AdService._();
  factory AdService() => _i;
  AdService._();

  // ── IDs de prueba oficiales de Google ─────────────────────────────────────
  static const _interstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _rewardedId = 'ca-app-pub-3940256099942544/5224354917';

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  int _actionCount = 0;

  // ── Interstitial ──────────────────────────────────────────────────────────

  /// Pre-carga el interstitial. Llamar una vez al iniciar la app.
  void preloadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) => debugPrint('[Ad] Interstitial failed: $error'),
      ),
    );
  }

  /// Muestra interstitial cada N acciones (no cada vez, para no molestar).
  /// Devuelve true si se mostró.
  bool showInterstitialEvery(int n) {
    _actionCount++;
    if (_actionCount % n != 0) return false;
    final ad = _interstitial;
    if (ad == null) {
      preloadInterstitial(); // recargar para la próxima
      return false;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _interstitial = null;
        preloadInterstitial(); // pre-cargar el siguiente
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _interstitial = null;
        preloadInterstitial();
      },
    );
    ad.show();
    return true;
  }

  // ── Rewarded Video ────────────────────────────────────────────────────────

  /// Carga y muestra un rewarded video.
  /// [onRewarded] se llama cuando el usuario completó el video.
  void showRewarded({required VoidCallback onRewarded}) {
    if (_rewarded != null) {
      _showRewarded(onRewarded);
      return;
    }
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _showRewarded(onRewarded);
        },
        onAdFailedToLoad: (error) {
          debugPrint('[Ad] Rewarded failed: $error');
          // Si falla, dar recompensa igual (mejor UX)
          onRewarded();
        },
      ),
    );
  }

  void _showRewarded(VoidCallback onRewarded) {
    final ad = _rewarded;
    if (ad == null) return;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _rewarded = null;
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _rewarded = null;
        onRewarded(); // si falla, dar recompensa igual
      },
    );
    ad.show(onUserEarnedReward: (_, __) => onRewarded());
  }
}
