import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/service_model.dart';
import '../../providers/app_settings.dart';
import '../../services/service_catalog_service.dart';

class ServiceCatalogScreen extends StatefulWidget {
  const ServiceCatalogScreen({super.key});

  @override
  State<ServiceCatalogScreen> createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  final _svc = ServiceCatalogService();
  List<ServiceModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await _svc.getAll();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openSheet([ServiceModel? existing]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ServiceSheet(
        existing: existing,
        onSave: (s) async {
          if (existing == null) {
            await _svc.create(s);
          } else {
            await _svc.update(s);
          }
          await _load();
        },
      ),
    );
  }

  Future<void> _toggleActive(ServiceModel s) async {
    await _svc.update(s.copyWith(isActive: !s.isActive));
    await _load();
  }

  Future<void> _confirmDelete(ServiceModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: Text('¿Eliminar "${s.name}"?\nEste servicio puede estar asignado a turnos existentes. ¿Eliminar de todas formas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      await _svc.delete(s.id);
      await _load();
    }
  }

  static IconData _iconForBusiness(String type) {
    switch (type.toLowerCase()) {
      case 'peluquería': return Icons.content_cut;
      case 'barbería':   return Icons.face_retouching_natural;
      case 'estética':   return Icons.spa;
      case 'tatuaje':    return Icons.brush;
      case 'uñas':       return Icons.colorize;
      case 'masajes':    return Icons.self_improvement;
      default:           return Icons.miscellaneous_services;
    }
  }

  // Agrupa los items por categoria
  Map<String, List<ServiceModel>> get _grouped {
    final Map<String, List<ServiceModel>> map = {};
    for (final item in _items) {
      final cat = item.category.isEmpty ? 'Sin categoría' : item.category;
      (map[cat] ??= []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de servicios'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _emptyState()
              : _list(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo servicio'),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cut_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No hay servicios aún.\nAgregá el primero.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openSheet(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar servicio'),
            ),
          ],
        ),
      );

  Widget _list() {
    final businessType = context.watch<AppSettingsProvider>().businessType;
    final leadingIcon = _iconForBusiness(businessType);
    final grouped = _grouped;
    final cats = grouped.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: cats.length,
      itemBuilder: (_, ci) {
        final cat = cats[ci];
        final services = grouped[cat]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cat != 'Sin categoría' || cats.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ...services.map(
              (s) => Dismissible(
                key: ValueKey(s.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  await _confirmDelete(s);
                  return false; // reload handles UI update
                },
                child: ListTile(
                  leading: Icon(
                    leadingIcon,
                    color: s.isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white24,
                  ),
                  title: Text(
                    s.name,
                    style: TextStyle(
                      color: s.isActive ? null : Colors.white38,
                      decoration: s.isActive ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    '${s.durationMinutes} min  ·  \$${s.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: s.isActive ? Colors.white54 : Colors.white24,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: s.isActive,
                        onChanged: (_) => _toggleActive(s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _openSheet(s),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 0),
          ],
        );
      },
    );
  }
}

// ── Bottom sheet: Agregar / Editar ──────────────────────────────────────────

class _ServiceSheet extends StatefulWidget {
  final ServiceModel? existing;
  final Future<void> Function(ServiceModel) onSave;

  const _ServiceSheet({this.existing, required this.onSave});

  @override
  State<_ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends State<_ServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _catCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _priceCtrl;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _catCtrl = TextEditingController(text: e?.category ?? '');
    _durationCtrl = TextEditingController(text: e != null ? '${e.durationMinutes}' : '30');
    _priceCtrl = TextEditingController(text: e != null ? '${e.price.toStringAsFixed(0)}' : '');
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _durationCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final model = ServiceModel(
      id: widget.existing?.id ?? '${DateTime.now().microsecondsSinceEpoch}_${(1000 + (DateTime.now().millisecond % 9000)).toString()}',
      name: _nameCtrl.text.trim(),
      durationMinutes: int.parse(_durationCtrl.text.trim()),
      price: double.parse(_priceCtrl.text.trim().replaceAll(',', '.')),
      category: _catCtrl.text.trim(),
      isActive: _isActive,
    );

    await widget.onSave(model);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.existing == null ? 'Nuevo servicio' : 'Editar servicio';
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Nombre
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del servicio *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 14),

            // Categoría
            TextFormField(
              controller: _catCtrl,
              decoration: const InputDecoration(
                labelText: 'Categoría (opcional)',
                hintText: 'Ej: Corte, Color, Tratamiento',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),

            // Duración y precio en la misma fila
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Duración (min) *',
                      border: OutlineInputBorder(),
                      suffixText: 'min',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Precio *',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      final n =
                          double.tryParse(v.trim().replaceAll(',', '.'));
                      if (n == null || n < 0) return 'Inválido';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Activo
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Servicio activo'),
              subtitle: const Text('Visible al crear turnos',
                  style: TextStyle(fontSize: 12)),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
