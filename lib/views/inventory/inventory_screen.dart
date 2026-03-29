import 'package:flutter/material.dart';
import '../../models/supply.dart';
import '../../services/supply_service.dart';

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
        title: const Text('Nuevo insumo'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                validator: (v) => (int.tryParse(v ?? '') == null) ? 'Número' : null,
              ),
              TextFormField(
                controller: minQty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Mínimo para aviso'),
                validator: (v) => (int.tryParse(v ?? '') == null) ? 'Número' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!key.currentState!.validate()) return;
              await _svc.create(
                name: name.text.trim(),
                qty: int.parse(qty.text),
                minQty: int.parse(minQty.text),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(Supply s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar insumo'),
        content: Text(
            '¿Eliminar "${s.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return ok ?? false;
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
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final ok = await _confirmDelete(s);
                if (!mounted) return;
                if (ok) await _svc.delete(s.id);
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
        title: const Text('Editar insumo'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
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
          ElevatedButton(
            onPressed: () async {
              if (!key.currentState!.validate()) return;
              await _svc.update(
                s.id,
                name: nameCtrl.text.trim(),
                qty: int.parse(qtyCtrl.text),
                minQty: int.parse(minCtrl.text),
              );
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
    return Dismissible(
      key: ValueKey(s.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(s),
      onDismissed: (_) => _svc.delete(s.id),
      child: ListTile(
        onLongPress: () => _showOptions(s),
        leading: Icon(Icons.inventory_2, color: low ? Colors.orange : null),
        title: Text(s.name),
        subtitle: Text('Stock: ${s.qty} · Mín: ${s.minQty}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '–1',
              icon: const Icon(Icons.remove),
              onPressed: () => _svc.updateQty(s.id, s.qty - 1),
            ),
            IconButton(
              tooltip: '+1',
              icon: const Icon(Icons.add),
              onPressed: () => _svc.updateQty(s.id, s.qty + 1),
            ),
          ],
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
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final items = snap.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('Sin insumos. Agregá uno.'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) => _tile(items[i]),
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


