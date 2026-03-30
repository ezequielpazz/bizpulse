import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../models/user_plan.dart';
import '../../services/subscription_service.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final _sub = SubscriptionService();
  List<Package> _packages = [];
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final pkgs = await _sub.fetchPackages();
    if (mounted) setState(() { _packages = pkgs; _loading = false; });
  }

  Future<void> _purchasePkg(String keyword) async {
    final pkg = _findPackage(keyword);
    setState(() => _purchasing = true);
    final success = await _sub.purchasePackage(pkg);
    if (mounted) {
      setState(() => _purchasing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido al plan ${_sub.currentPlan.label}!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    final restored = await _sub.restore();
    if (mounted) {
      setState(() => _purchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(restored
              ? 'Suscripción restaurada: ${_sub.currentPlan.label}'
              : 'No se encontraron compras previas'),
        ),
      );
      if (restored) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = _sub.currentPlan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegí tu plan'),
        actions: [
          TextButton(
            onPressed: _purchasing ? null : _restore,
            child: const Text('Restaurar compra'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Text(
                  'Hacé crecer tu negocio',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Elegí el plan que mejor se adapte a vos',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Free
                _PlanCard(
                  plan: AppPlan.free,
                  isCurrent: current == AppPlan.free,
                  highlighted: false,
                  features: const [
                    'Agenda de turnos',
                    'Clientes ilimitados',
                    'Cobro rápido',
                    'Inventario básico',
                    'Reporte mensual',
                    'Recordatorios',
                  ],
                  limitations: const [
                    'Con anuncios',
                  ],
                  onSubscribe: null,
                  purchasing: _purchasing,
                ),
                const SizedBox(height: 16),

                // Pro
                _PlanCard(
                  plan: AppPlan.pro,
                  isCurrent: current == AppPlan.pro,
                  highlighted: true,
                  badge: 'Más popular',
                  features: const [
                    'Todo lo de Free',
                    'Sin anuncios',
                    'Reportes avanzados',
                    'Recordatorio WhatsApp automático',
                    'Agenda con colores por servicio',
                    'Backup automático diario',
                    'Notas por turno',
                  ],
                  limitations: const [],
                  onSubscribe: _packages.isNotEmpty && !current.includes(AppPlan.pro)
                      ? () => _purchasePkg('pro')
                      : null,
                  purchasing: _purchasing,
                ),
                const SizedBox(height: 16),

                // Enterprise
                _PlanCard(
                  plan: AppPlan.enterprise,
                  isCurrent: current == AppPlan.enterprise,
                  highlighted: false,
                  features: const [
                    'Todo lo de Pro',
                    'Multi-empleado',
                    'Dashboard de equipo',
                    'Link de reservas público',
                    'Gestión de comisiones',
                    'Exportar a Excel',
                    'Logo personalizado en reportes',
                    'Soporte prioritario',
                  ],
                  limitations: const [],
                  onSubscribe: _packages.isNotEmpty && !current.includes(AppPlan.enterprise)
                      ? () => _purchasePkg('enterprise')
                      : null,
                  purchasing: _purchasing,
                ),

                const SizedBox(height: 24),
                // Legal
                Text(
                  'La suscripción se renueva automáticamente. '
                  'Podés cancelar en cualquier momento desde Google Play. '
                  'El pago se carga a tu cuenta de Google Play.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Package _findPackage(String keyword) {
    // Buscar por identifier que contenga 'pro' o 'enterprise'
    return _packages.firstWhere(
      (p) => p.storeProduct.identifier.toLowerCase().contains(keyword),
      orElse: () => _packages.first,
    );
  }
}

// ── Card de plan ──────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final AppPlan plan;
  final bool isCurrent;
  final bool highlighted;
  final String? badge;
  final List<String> features;
  final List<String> limitations;
  final VoidCallback? onSubscribe;
  final bool purchasing;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.highlighted,
    this.badge,
    required this.features,
    required this.limitations,
    required this.onSubscribe,
    required this.purchasing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: highlighted ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: highlighted
            ? BorderSide(color: primary, width: 2)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name + price
                Row(
                  children: [
                    Icon(
                      plan == AppPlan.free
                          ? Icons.rocket_launch_outlined
                          : plan == AppPlan.pro
                              ? Icons.star_rounded
                              : Icons.diamond_rounded,
                      color: highlighted ? primary : Colors.grey[600],
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.label,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            plan.priceLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: highlighted ? primary : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          'Tu plan',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Features
                ...features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(f, style: const TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    )),

                // Limitations
                ...limitations.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle_outline,
                              color: Colors.orange[400], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.orange[200] : Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                // Button
                if (!isCurrent && onSubscribe != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: purchasing ? null : onSubscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: highlighted ? primary : null,
                        foregroundColor: highlighted ? Colors.white : null,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: purchasing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Suscribirme a ${plan.label}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
                if (isCurrent && plan != AppPlan.free) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Plan activo'),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Badge "Más popular"
          if (badge != null)
            Positioned(
              top: 0,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
