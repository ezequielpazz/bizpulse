import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_plan.dart';

/// Servicio centralizado de suscripciones con RevenueCat.
/// Singleton — usar SubscriptionService() en toda la app.
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _i = SubscriptionService._();
  factory SubscriptionService() => _i;
  SubscriptionService._();

  // ── IDs de productos (deben coincidir con Play Console + RevenueCat) ──────
  static const _proEntitlementId = 'pro';
  static const _enterpriseEntitlementId = 'enterprise';

  // TODO: Reemplazar con tu API key real de RevenueCat
  static const _revenueCatApiKey = 'YOUR_REVENUECAT_API_KEY';

  bool _initialized = false;
  AppPlan _currentPlan = AppPlan.free;
  List<Package> _availablePackages = [];

  /// Plan actual del usuario.
  AppPlan get currentPlan => _currentPlan;

  /// Paquetes disponibles para comprar.
  List<Package> get availablePackages => _availablePackages;

  /// Shorthand checks.
  bool get isPro => _currentPlan.includes(AppPlan.pro);
  bool get isEnterprise => _currentPlan.includes(AppPlan.enterprise);
  bool get isFree => _currentPlan == AppPlan.free;

  // ── Inicialización ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Purchases.setLogLevel(LogLevel.warn);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      final config = PurchasesConfiguration(_revenueCatApiKey);
      if (uid != null) {
        config..appUserID = uid;
      }
      await Purchases.configure(config);

      // Escuchar cambios de suscripción en tiempo real
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Verificar estado actual
      await refreshPlan();

      _initialized = true;
    } catch (e) {
      debugPrint('[Subscriptions] Error al inicializar RevenueCat: $e');
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _updatePlanFromInfo(info);
  }

  // ── Consultar plan ────────────────────────────────────────────────────────

  Future<void> refreshPlan() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _updatePlanFromInfo(info);
    } catch (e) {
      debugPrint('[Subscriptions] Error al consultar plan: $e');
      // Fallback: leer de Firestore
      await _readPlanFromFirestore();
    }
  }

  void _updatePlanFromInfo(CustomerInfo info) {
    final entitlements = info.entitlements.active;

    AppPlan newPlan;
    if (entitlements.containsKey(_enterpriseEntitlementId)) {
      newPlan = AppPlan.enterprise;
    } else if (entitlements.containsKey(_proEntitlementId)) {
      newPlan = AppPlan.pro;
    } else {
      newPlan = AppPlan.free;
    }

    if (newPlan != _currentPlan) {
      _currentPlan = newPlan;
      notifyListeners();
      // Sincronizar a Firestore para que las rules lo vean
      _syncPlanToFirestore(newPlan);
    }
  }

  // ── Comprar ───────────────────────────────────────────────────────────────

  /// Obtener ofertas disponibles.
  Future<List<Package>> fetchPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current != null) {
        _availablePackages = current.availablePackages;
      }
      return _availablePackages;
    } catch (e) {
      debugPrint('[Subscriptions] Error al obtener ofertas: $e');
      return [];
    }
  }

  /// Comprar un paquete de suscripción.
  /// Retorna true si la compra fue exitosa.
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      _updatePlanFromInfo(result.customerInfo);
      return _currentPlan.isPaid;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[Subscriptions] Compra cancelada por el usuario');
      } else {
        debugPrint('[Subscriptions] Error en compra: $e');
      }
      return false;
    } catch (e) {
      debugPrint('[Subscriptions] Error inesperado en compra: $e');
      return false;
    }
  }

  /// Restaurar compras previas (reinstalación, cambio de dispositivo).
  Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      _updatePlanFromInfo(info);
      return _currentPlan.isPaid;
    } catch (e) {
      debugPrint('[Subscriptions] Error al restaurar: $e');
      return false;
    }
  }

  // ── Firestore sync ────────────────────────────────────────────────────────

  Future<void> _syncPlanToFirestore(AppPlan plan) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'plan': plan.name,
        'planUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Subscriptions] Error sync Firestore: $e');
    }
  }

  Future<void> _readPlanFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final planStr = doc.data()?['plan'] as String? ?? 'free';
      _currentPlan = AppPlan.values.firstWhere(
        (p) => p.name == planStr,
        orElse: () => AppPlan.free,
      );
      notifyListeners();
    } catch (_) {}
  }

  // ── Identificar usuario (llamar tras login) ──────────────────────────────

  Future<void> login(String uid) async {
    try {
      final result = await Purchases.logIn(uid);
      _updatePlanFromInfo(result.customerInfo);
    } catch (e) {
      debugPrint('[Subscriptions] Error login RevenueCat: $e');
    }
  }

  Future<void> logout() async {
    try {
      if (await Purchases.isAnonymous == false) {
        await Purchases.logOut();
      }
      _currentPlan = AppPlan.free;
      notifyListeners();
    } catch (_) {}
  }
}
