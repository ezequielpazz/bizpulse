import '../models/user_plan.dart';
import 'subscription_service.dart';

/// Define qué features requieren qué plan.
/// Usar: FeatureGate.canUse(Feature.noAds)
enum Feature {
  // ── Pro features ──
  noAds(AppPlan.pro),
  advancedReports(AppPlan.pro),
  autoWhatsAppReminder(AppPlan.pro),
  colorAgenda(AppPlan.pro),
  autoBackup(AppPlan.pro),
  serviceNotes(AppPlan.pro),

  // ── Enterprise features ──
  multiEmployee(AppPlan.enterprise),
  teamDashboard(AppPlan.enterprise),
  publicBookingLink(AppPlan.enterprise),
  commissions(AppPlan.enterprise),
  excelExport(AppPlan.enterprise),
  customLogo(AppPlan.enterprise),
  prioritySupport(AppPlan.enterprise);

  final AppPlan requiredPlan;
  const Feature(this.requiredPlan);
}

/// Gate centralizado para chequear acceso a features.
class FeatureGate {
  FeatureGate._();

  static final _sub = SubscriptionService();

  /// True si el usuario puede usar esta feature con su plan actual.
  static bool canUse(Feature feature) =>
      _sub.currentPlan.includes(feature.requiredPlan);

  /// Plan mínimo requerido para la feature.
  static AppPlan requiredPlan(Feature feature) => feature.requiredPlan;

  /// True si el plan actual es Free (= mostrar ads).
  static bool get showAds => _sub.isFree;

  /// True si el plan actual incluye Pro o superior.
  static bool get isPro => _sub.isPro;

  /// True si el plan actual es Enterprise.
  static bool get isEnterprise => _sub.isEnterprise;
}
