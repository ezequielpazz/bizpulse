import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/appointment.dart';
import '../../models/supply.dart';
import '../../providers/app_settings.dart';
import '../../services/appointment_service.dart';
import '../../services/supply_service.dart';
import '../../services/ad_service.dart';
import '../../services/finance_service.dart';
import '../../models/transaction_model.dart';
import '../../widgets/ad_banner.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int tabIndex) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _proBannerDismissed = false;

  // Streams cacheados: se crean UNA sola vez y reutilizan en todos los builders
  late final Stream<List<Appointment>> _todayStream;
  late final Stream<List<Appointment>> _nextStream;
  late final Stream<List<Supply>> _supplyStream;

  @override
  void initState() {
    super.initState();
    final svc = AppointmentService();
    _todayStream = svc.streamForDay(DateTime.now()).asBroadcastStream();
    _nextStream = svc.streamUpcoming(limit: 1).asBroadcastStream();
    _supplyStream = SupplyService().streamAll().asBroadcastStream();
    _loadBannerState();
  }

  Future<void> _loadBannerState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() =>
          _proBannerDismissed = prefs.getBool('pro_banner_dismissed') ?? false);
    }
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pro_banner_dismissed', true);
    if (mounted) setState(() => _proBannerDismissed = true);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buen día ☀️';
    if (h < 19) return 'Buenas tardes 🌤️';
    return 'Buenas noches 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsProvider>();
    final today = DateTime.now();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _quickIncome,
        icon: const Icon(Icons.add),
        label: const Text('Cobro rápido'),
        backgroundColor: Colors.green.shade700,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              _header(s),
              const SizedBox(height: 16),
              _fadeIn(delay: 0, child: _todayCard(s, today)),
              const SizedBox(height: 12),
              _fadeIn(delay: 80, child: _cajaCard(s, today)),
              const SizedBox(height: 12),
              _fadeIn(delay: 160, child: _lowStockCard()),
              const SizedBox(height: 12),
              _fadeIn(delay: 240, child: _nextCard(s)),
              if (!_proBannerDismissed) ...[
                const SizedBox(height: 12),
                _fadeIn(delay: 320, child: _proBanner()),
              ],
              const SizedBox(height: 16),
              const Center(child: AdBannerWidget()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Animación de entrada staggered ─────────────────────────────────────────

  Widget _fadeIn({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOut,
      builder: (_, value, ch) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: ch,
        ),
      ),
      child: child,
    );
  }

  // ── Cobro rápido ───────────────────────────────────────────────────────────

  Future<void> _quickIncome() async {
    final s = context.read<AppSettingsProvider>();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController(text: 'Servicio');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cobro rápido',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto *',
                    prefixText: '${s.currencySymbol} ',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresá el monto';
                    final n = double.tryParse(v.trim().replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Monto inválido';
                    if (n > 9999999) return 'Monto demasiado alto';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setS(() => saving = true);
                            try {
                              await FinanceService().create(
                                type: TransactionType.income,
                                amount: double.parse(
                                    amountCtrl.text.trim().replaceAll(',', '.')),
                                description: descCtrl.text.trim().isEmpty
                                    ? 'Servicio'
                                    : descCtrl.text.trim(),
                                date: DateTime.now(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '✓ Cobro de ${s.currencySymbol} ${amountCtrl.text.trim()} registrado'),
                                    backgroundColor: Colors.green.shade700,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                // Interstitial cada 3 cobros (no cada vez)
                                AdService().showInterstitialEvery(3);
                              }
                            } catch (e) {
                              setS(() => saving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check),
                    label: Text(saving ? 'Guardando...' : 'Registrar cobro'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _header(AppSettingsProvider s) {
    return Row(
      children: [
        Image.asset('assets/icon/app_icon.png', height: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              if (s.businessType.isNotEmpty)
                Text(
                  s.businessType,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Card: Turnos de hoy ────────────────────────────────────────────────────

  Widget _todayCard(AppSettingsProvider s, DateTime today) {
    return StreamBuilder<List<Appointment>>(
      stream: _todayStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shimmer(120);
        }
        final appts = snap.data ?? [];
        final now = DateTime.now();
        final upcoming = (appts.where((a) => a.when.isAfter(now)).toList()
          ..sort((a, b) => a.when.compareTo(b.when)))
            .take(3)
            .toList();

        return _card(
          title: 'Turnos de hoy',
          icon: Icons.event,
          onTap: () => widget.onNavigate(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${appts.length} turno${appts.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (upcoming.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Sin turnos pendientes hoy 🎉',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                )
              else
                ...upcoming.map((a) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Text(DateFormat.Hm().format(a.when),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a.clientName +
                                  (a.service != null
                                      ? '  ·  ${a.service}'
                                      : ''),
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  // ── Card: Caja del día ─────────────────────────────────────────────────────

  Widget _cajaCard(AppSettingsProvider s, DateTime today) {
    return StreamBuilder<List<Appointment>>(
      stream: _todayStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shimmer(80);
        }
        final total = (snap.data ?? [])
            .fold<double>(0, (sum, a) => sum + (a.price ?? 0));
        return _card(
          title: 'Caja del día',
          icon: Icons.attach_money,
          onTap: () => widget.onNavigate(4),
          child: Text(
            s.stealthMode
                ? '••••'
                : '${s.currencySymbol} ${total.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  // ── Card: Stock bajo ───────────────────────────────────────────────────────

  Widget _lowStockCard() {
    return StreamBuilder<List<Supply>>(
      stream: _supplyStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting ||
            snap.data == null) {
          return const SizedBox.shrink();
        }
        final low =
            snap.data!.where((s) => s.qty <= s.minQty).toList();
        if (low.isEmpty) return const SizedBox.shrink();

        return _card(
          title: 'Stock bajo ⚠️',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orange,
          onTap: () => widget.onNavigate(2),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: low
                .map((s) => Chip(
                      label: Text('${s.name} (${s.qty})',
                          style: const TextStyle(fontSize: 11)),
                      backgroundColor:
                          Colors.orange.withValues(alpha: 0.15),
                      side: const BorderSide(
                          color: Colors.orange, width: 0.5),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  // ── Card: Próximo turno ────────────────────────────────────────────────────

  Widget _nextCard(AppSettingsProvider s) {
    return StreamBuilder<List<Appointment>>(
      stream: _nextStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shimmer(80);
        }
        final next =
            snap.data?.isNotEmpty == true ? snap.data!.first : null;
        return _card(
          title: 'Próximo turno',
          icon: Icons.schedule,
          onTap: () => widget.onNavigate(1),
          child: next == null
              ? const Text('No hay turnos agendados',
                  style: TextStyle(color: Colors.grey))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(next.clientName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(next.when)}'
                      '  ·  ${DateFormat.Hm().format(next.when)}'
                      '${next.service != null ? '  ·  ${next.service}' : ''}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ── Banner Pro ─────────────────────────────────────────────────────────────

  Widget _proBanner() {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('¿Querés más?',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                InkWell(
                  onTap: _dismissBanner,
                  child: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'BizPulse Pro — sync en la nube, sin anuncios, backup automático',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _showPlansDialog,
              child: const Text('Ver planes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlansDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Planes BizPulse'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PlanTile(name: 'Free', price: r'$0', features: const [
                '1 usuario',
                'Datos locales',
                'Sin backup automático',
              ]),
              const Divider(),
              _PlanTile(
                  name: 'Pro 🚀',
                  price: r'USD $10/mes',
                  highlight: true,
                  features: const [
                    'Sync en la nube',
                    'Sin anuncios',
                    'Backup automático',
                    'Soporte prioritario',
                  ]),
              const Divider(),
              _PlanTile(
                  name: 'Enterprise',
                  price: r'USD $20/mes',
                  features: const [
                    'Multi-usuario',
                    'Reportes avanzados',
                    'Integración WhatsApp Business',
                  ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _card({
    required String title,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon,
                      size: 14,
                      color: iconColor ??
                          Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmer(double height) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: height,
        child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

// ── Plan tile ──────────────────────────────────────────────────────────────────

class _PlanTile extends StatelessWidget {
  final String name;
  final String price;
  final List<String> features;
  final bool highlight;

  const _PlanTile({
    required this.name,
    required this.price,
    required this.features,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: highlight ? color : null)),
              const Spacer(),
              Text(price, style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 13, color: color),
                    const SizedBox(width: 4),
                    Text(f, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
