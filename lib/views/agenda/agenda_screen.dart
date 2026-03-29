import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/appointment.dart';
import '../../models/service_model.dart';
import '../../providers/app_settings.dart';
import '../../models/client_model.dart';
import '../../services/appointment_service.dart';
import '../../services/client_service.dart';
import '../../services/service_catalog_service.dart';
import '../services/service_catalog_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});
  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _svc = AppointmentService();
  DateTime _selectedDay = DateTime.now();
  bool _weekMode = false;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _monday(DateTime.now());
    _loadViewPref();
  }

  DateTime _monday(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  Future<void> _loadViewPref() async {
    final prefs = await SharedPreferences.getInstance();
    final isWeek = prefs.getBool('agenda_view_mode_week') ?? false;
    if (mounted) setState(() => _weekMode = isWeek);
  }

  Future<void> _toggleView() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weekMode = !_weekMode;
      if (_weekMode) _weekStart = _monday(_selectedDay);
    });
    await prefs.setBool('agenda_view_mode_week', _weekMode);
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _selectedDay = picked);
  }

  Future<void> _add() async {
    final rawRemind = context.read<AppSettingsProvider>().notifMinutesBefore;
    final remindMin = const {1440, 120, 60, 30}.contains(rawRemind) ? rawRemind : 60;
    await showDialog(
      context: context,
      builder: (_) => _NewTurnoDialog(
        svc: _svc,
        clientSvc: ClientService(),
        catalogSvc: ServiceCatalogService(),
        selectedDay: _selectedDay,
        initialRemindMin: remindMin,
      ),
    );
  }

  Widget _tile(Appointment a) {
    final hhmm = DateFormat.Hm().format(a.when);
    final service = (a.service?.isNotEmpty ?? false) ? ' · ${a.service}' : '';
    final price = (a.price != null) ? ' · \$${a.price!.toStringAsFixed(0)}' : '';
    return ListTile(
      leading: const Icon(Icons.event),
      title: Text(a.clientName),
      subtitle: Text('$hhmm$service$price'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _confirmDelete(a.id),
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar turno'),
        content: const Text('¿Seguro que querés eliminar este turno?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _svc.delete(id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  Widget _buildWeekView() {
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final today = DateTime.now();
    final rangeLabel =
        '${DateFormat('dd MMM', 'es').format(_weekStart)} – '
        '${DateFormat('dd MMM yyyy', 'es').format(_weekStart.add(const Duration(days: 6)))}';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(
                  () => _weekStart = _weekStart.subtract(const Duration(days: 7))),
            ),
            Text(rangeLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(
                  () => _weekStart = _weekStart.add(const Duration(days: 7))),
            ),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: days.map((d) => _dayColumn(d, today)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _dayColumn(DateTime day, DateTime today) {
    final isToday = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    final isSelected = day.year == _selectedDay.year &&
        day.month == _selectedDay.month &&
        day.day == _selectedDay.day;
    final primary = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedDay = day;
          _weekMode = false;
        }),
        child: StreamBuilder<List<Appointment>>(
          stream: _svc.streamForDay(day),
          builder: (context, snap) {
            final items = snap.data ?? [];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withValues(alpha: 0.25)
                    : isToday
                        ? Colors.white10
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: primary, width: 1.5)
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('E', 'es').format(day).substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday ? primary : Colors.white54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: isToday ? primary : Colors.transparent,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isToday ? Colors.white : Colors.white70,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...items.take(3).map((_) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                      )),
                  if (items.length > 3)
                    Text('+${items.length - 3}',
                        style: const TextStyle(fontSize: 9, color: Colors.white54)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_weekMode
            ? 'Semana'
            : 'Agenda — ${DateFormat('dd/MM/yyyy').format(_selectedDay)}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_weekMode
                ? Icons.view_list_outlined
                : Icons.calendar_view_week_outlined),
            tooltip: _weekMode ? 'Vista lista' : 'Vista semanal',
            onPressed: _toggleView,
          ),
          IconButton(onPressed: _pickDay, icon: const Icon(Icons.calendar_today)),
        ],
      ),
      body: _weekMode
          ? _buildWeekView()
          : StreamBuilder<List<Appointment>>(
              stream: _svc.streamForDay(_selectedDay),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return const Center(child: Text('No hay turnos en este día.'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _tile(items[i]),
                  separatorBuilder: (_, __) => const Divider(height: 0),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo turno'),
      ),
    );
  }
}

// ── Diálogo de nuevo turno ─────────────────────────────────────────────────────
// Carga clientes y servicios en initState() para no bloquear el hilo de UI
// antes de mostrar el diálogo.

class _NewTurnoDialog extends StatefulWidget {
  final AppointmentService svc;
  final ClientService clientSvc;
  final ServiceCatalogService catalogSvc;
  final DateTime selectedDay;
  final int initialRemindMin;

  const _NewTurnoDialog({
    required this.svc,
    required this.clientSvc,
    required this.catalogSvc,
    required this.selectedDay,
    required this.initialRemindMin,
  });

  @override
  State<_NewTurnoDialog> createState() => _NewTurnoDialogState();
}

class _NewTurnoDialogState extends State<_NewTurnoDialog> {
  bool _loading = true;
  bool _saving = false;

  List<ServiceModel> _activeServices = [];
  List<ClientModel> _allClients = [];

  final _serviceCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ClientModel? _selClient;
  TextEditingController? _autoNameCtrl;
  ServiceModel? _selectedService;
  late TimeOfDay _initial;
  late int _remindMin;

  @override
  void initState() {
    super.initState();
    final base = DateTime.now().isAfter(widget.selectedDay)
        ? DateTime.now()
        : DateTime(
            widget.selectedDay.year,
            widget.selectedDay.month,
            widget.selectedDay.day,
            10,
          );
    _initial = TimeOfDay(hour: base.hour, minute: (base.minute ~/ 30) * 30);
    _remindMin = widget.initialRemindMin;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        widget.catalogSvc.getActive(),
        widget.clientSvc.getAll(),
      ]);
      if (mounted) {
        setState(() {
          _activeServices = results[0] as List<ServiceModel>;
          _allClients = results[1] as List<ClientModel>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _serviceCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final dt = DateTime(
        widget.selectedDay.year,
        widget.selectedDay.month,
        widget.selectedDay.day,
        _initial.hour,
        _initial.minute,
      );
      final clientName = _autoNameCtrl?.text.trim() ?? '';
      final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
      await widget.svc.create(
        clientName: clientName,
        whenLocal: dt,
        service: _serviceCtrl.text.trim().isEmpty ? null : _serviceCtrl.text.trim(),
        price: price,
        remindBeforeMin: _remindMin,
      );
      if (_selClient != null) {
        try {
          await widget.clientSvc.incrementVisit(_selClient!.id, price ?? 0);
        } catch (_) {}
      }
      if (mounted) Navigator.pop(context);
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
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Nuevo turno'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<ClientModel>(
                optionsBuilder: (tv) {
                  if (tv.text.isEmpty) return const Iterable<ClientModel>.empty();
                  final q = tv.text.toLowerCase();
                  return _allClients.where((c) => c.name.toLowerCase().contains(q));
                },
                displayStringForOption: (c) => c.name,
                onSelected: (c) => setState(() => _selClient = c),
                fieldViewBuilder: (ctx2, ctrl, fn, onFS) {
                  _autoNameCtrl = ctrl;
                  return TextFormField(
                    controller: ctrl,
                    focusNode: fn,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    onChanged: (_) => _selClient = null,
                  );
                },
              ),
              const SizedBox(height: 8),

              if (_activeServices.isNotEmpty) ...[
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Catálogo (opcional)',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ServiceModel?>(
                      value: _selectedService,
                      isExpanded: true,
                      hint: const Text('Sin seleccionar'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('— Sin seleccionar —'),
                        ),
                        ..._activeServices.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              '${s.name}  ·  \$${s.price.toStringAsFixed(0)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (s) => setState(() {
                        _selectedService = s;
                        if (s != null) {
                          _serviceCtrl.text = s.name;
                          _priceCtrl.text = s.price.toStringAsFixed(0);
                        } else {
                          _serviceCtrl.clear();
                          _priceCtrl.clear();
                        }
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              TextFormField(
                controller: _serviceCtrl,
                decoration: InputDecoration(
                  labelText: _activeServices.isEmpty
                      ? 'Servicio (opcional)'
                      : 'Servicio (editable)',
                ),
              ),

              if (_activeServices.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Agregar servicios al catálogo',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServiceCatalogScreen(),
                        ),
                      );
                    },
                  ),
                ),

              TextFormField(
                controller: _priceCtrl,
                decoration:
                    const InputDecoration(labelText: 'Precio (opcional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Text('Hora:  '),
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: _initial);
                      if (t != null) setState(() => _initial = t);
                    },
                    child: const Text('Elegir'),
                  ),
                  const Spacer(),
                  Text(_initial.format(context)),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Text('Avisar:'),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _remindMin,
                    items: const [
                      DropdownMenuItem(
                          value: 1440, child: Text('24 horas antes')),
                      DropdownMenuItem(
                          value: 120, child: Text('2 horas antes')),
                      DropdownMenuItem(
                          value: 60, child: Text('1 hora antes')),
                      DropdownMenuItem(
                          value: 30, child: Text('30 minutos antes')),
                    ],
                    onChanged: (v) => setState(() => _remindMin = v ?? 60),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
