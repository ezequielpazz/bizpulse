/// Planes disponibles en BizPulse.
enum AppPlan { free, pro, enterprise }

/// Extension para obtener info del plan fácilmente.
extension AppPlanX on AppPlan {
  String get label {
    switch (this) {
      case AppPlan.free:
        return 'Free';
      case AppPlan.pro:
        return 'Pro';
      case AppPlan.enterprise:
        return 'Enterprise';
    }
  }

  String get priceLabel {
    switch (this) {
      case AppPlan.free:
        return 'Gratis';
      case AppPlan.pro:
        return '\$10/mes';
      case AppPlan.enterprise:
        return '\$20/mes';
    }
  }

  bool get isPaid => this != AppPlan.free;

  /// True si este plan incluye las features del plan dado.
  bool includes(AppPlan required) => index >= required.index;
}
