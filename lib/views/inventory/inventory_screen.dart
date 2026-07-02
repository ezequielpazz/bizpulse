import 'package:flutter/material.dart';
import '../../models/supply.dart';
import '../../services/supply_service.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/ui_kit.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _svc = SupplyService();

  Future<void> _add() async {
    final name = TextEditingController();
    final qty = TextEditingController();
    final minQty = TextEditingController(text: '10');
    final key = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nuevo insumo'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                validator: (v) =>
                    (int.tryParse(v ?? '') == null) ? 'Número' : null,
              ),
              TextFormField(
                controller: minQty,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Mínimo para aviso'),
                validator: (v) =>
                    (int.tryParse(v ?? '') == null) ? 'Número' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!key.currentState!.validate()) return;
              try {
                await _svc.create(
                  name: name.text.trim(),
                  qty: int.parse(qty.text),
                  minQty: int.parse(minQty.text),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar: $e')),
                  );
                }
                return;
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showOptions(Supply s) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _edit(s);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Eliminar',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () async {
                Navigator.pop(context);
                final ok = await confirmDelete(
                  context,
                  title: 'Eliminar insumo',
                  message:
                      '¿Eliminar "${s.name}"? Esta acción no se puede deshacer.',
                );
                if (!mounted) return;
                if (ok) {
                  try {
                    await _svc.delete(s.id);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al eliminar: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(Supply s) async {
    final nameCtrl = TextEditingController(text: s.name);
    final qtyCtrl = TextEditingController(text: s.qty.toString());
    final minCtrl = TextEditingController(text: s.minQty.toString());
    final key = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar insumo'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                validator: (v) =>
                    (int.tryParse(v ?? '') == null) ? 'Número' : null,
              ),
              TextFormField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Mínimo para aviso'),
                validator: (v) =>
                    (int.tryParse(v ?? '') == null) ? 'Número' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!key.currentState!.validate()) return;
              try {
                await _svc.update(
                  s.id,
                  name: nameCtrl.text.trim(),
                  qty: int.parse(qtyCtrl.text),
                  minQty: int.parse(minCtrl.text),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar: $e')),
                  );
                }
                return;
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _tile(Supply s) {
    final low = s.qty <= s.minQty;
    final warn = Colors.orange;
    final primary = Theme.of(context).colorScheme.primary;
    final accent = low ? warn : primary;
    // Nivel de stock relativo al mínimo (para la barrita visual)
    final level = s.minQty <= 0
        ? 1.0
        : (s.qty / (s.minQty * 2)).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Dismissible(
        key: ValueKey(s.id),
        direction: DismissDirection.endToStart,
        background: const DismissDeleteBackground(),
        confirmDismiss: (_) => confirmDelete(
          context,
          title: 'Eliminar insumo',
          message: '¿Eliminar "${s.name}"? Esta acción no se puede deshacer.',
        ),
        onDismissed: (_) => _svc.delete(s.id),
        child: AppCard(
          onLongPress: () => _showOptions(s),
          onTap: () => _edit(s),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  low
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Barra de nivel de stock
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: level,
                        minHeight: 4,
                        backgroundColor: accent.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      low
                          ? 'Stock: ${s.qty} · Mín: ${s.minQty} · ¡Reponer!'
                          : 'Stock: ${s.qty} · Mín: ${s.minQty}',
                      style: TextStyle(
                        fontSize: 11,
                        color: low ? warn : Theme.of(context).hintColor,
                        fontWeight: low ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Stepper -1 / +1
              MiniAction(
                icon: Icons.remove_rounded,
                color: Theme.of(context).colorScheme.error,
                tooltip: 'Restar 1',
                onPressed: () => _svc.updateQty(s.id, s.qty - 1),
              ),
              const SizedBox(width: 6),
              MiniAction(
                icon: Icons.add_rounded,
                color: Colors.green,
                tooltip: 'Sumar 1',
                onPressed: () => _svc.updateQty(s.id, s.qty + 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insumos')),
      body: StreamBuilder<List<Supply>>(
        stream: _svc.streamAll(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorState(
              message: '${snap.error}',
              onRetry: () => setState(() {}),
            );
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_rounded,
              title: 'Sin insumos aún',
              subtitle:
                  'Cargá tus insumos de trabajo (tinturas, agujas, cremas...) y recibí alertas cuando queden pocos.',
            );
          }
          final lowCount = items.where((s) => s.qty <= s.minQty).length;
          return Column(
            children: [
              if (lowCount > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '$lowCount insumo${lowCount > 1 ? 's' : ''} con stock bajo',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 88),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _tile(items[i]),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: AdBannerWidget(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}
