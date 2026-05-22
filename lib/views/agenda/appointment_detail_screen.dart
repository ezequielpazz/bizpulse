import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import '../../services/feature_gate.dart';
import '../plans/plans_screen.dart';

/// Detalle de un turno con notas técnicas (Pro feature).
/// Permite ver/editar notas y revisar historial del cliente.
class AppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;
  final AppointmentService svc;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
    required this.svc,
  });

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late final TextEditingController _notesCtrl;
  bool _saving = false;
  bool _dirty = false;
  List<Appointment> _history = [];
  bool _loadingHistory = true;

  bool get _canUseNotes => FeatureGate.canUse(Feature.serviceNotes);

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.appointment.notes ?? '');
    _notesCtrl.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });
    if (_canUseNotes) _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await widget.svc.getHistoryForClient(
      widget.appointment.clientName,
    );
    if (mounted) {
      setState(() {
        _history = history.where((a) => a.id != widget.appointment.id).toList();
        _loadingHistory = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.svc.updateNotes(
        widget.appointment.id,
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _dirty = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notas guardadas')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    final df = DateFormat('EEEE d MMMM y · HH:mm', 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del turno'),
        actions: [
          if (_canUseNotes && _dirty)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info principal
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.clientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(df.format(a.when)),
                    ],
                  ),
                  if (a.service?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.cut, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(a.service!),
                      ],
                    ),
                  ],
                  if (a.price != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('\$${a.price!.toStringAsFixed(0)}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notas técnicas
          if (_canUseNotes) ...[
            const Text(
              'Notas técnicas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tono usado, productos, alergias, preferencias del cliente...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              minLines: 4,
              maxLines: 12,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'Ej: Tinte rubio nº9, decoloración previa, alérgica al amoníaco...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // Historial del cliente
            const Text(
              'Historial del cliente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_loadingHistory)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ))
            else if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Sin turnos previos con este cliente',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._history.map((h) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(DateFormat('d/M/y HH:mm').format(h.when)),
                      subtitle: Text(
                        [
                          if (h.service?.isNotEmpty ?? false) h.service!,
                          if (h.notes?.isNotEmpty ?? false)
                            '📝 ${h.notes!.length > 60 ? '${h.notes!.substring(0, 60)}...' : h.notes}'
                          else
                            'Sin notas',
                        ].join('\n'),
                      ),
                      isThreeLine: (h.notes?.isNotEmpty ?? false),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AppointmentDetailScreen(
                            appointment: h,
                            svc: widget.svc,
                          ),
                        ),
                      ),
                    ),
                  )),
          ] else
            // Paywall
            _ProPaywall(),
        ],
      ),
    );
  }
}

// ── Paywall card ─────────────────────────────────────────────────────────────

class _ProPaywall extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.star_rounded,
              size: 48,
              color: Colors.amber[700],
            ),
            const SizedBox(height: 12),
            const Text(
              'Notas técnicas e historial',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Llevá registro de qué hiciste en cada turno: tonos, productos, '
              'alergias, preferencias del cliente. Acordate de todo en el próximo '
              'turno y sorprendé a tu cliente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '✓ Notas ilimitadas por turno\n'
              '✓ Historial completo del cliente\n'
              '✓ Sin anuncios + reportes avanzados',
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.rocket_launch),
                label: const Text(
                  'Ver planes Pro',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlansScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
