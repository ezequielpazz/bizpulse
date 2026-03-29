import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _svc = ProductService();

  // ── Bottom sheet (add / edit) ───────────────────────────────────────────────

  Future<void> _openForm({Product? product}) async {
    await showDialog(
      context: context,
      builder: (_) => _ProductForm(svc: _svc, product: product),
    );
  }

  // ── Delete with confirmation ────────────────────────────────────────────────

  Future<bool> _confirmDelete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content:
            Text('¿Eliminar "${p.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
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

  // ── Long-press options ──────────────────────────────────────────────────────

  void _showProductOptions(Product p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _openForm(product: p);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final ok = await _confirmDelete(p);
                if (!mounted) return;
                if (ok) await _svc.delete(p.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Product card ────────────────────────────────────────────────────────────

  Widget _buildCard(Product p) {
    final isLow = p.isLowStock;

    return Dismissible(
      key: Key(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade900,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(p),
      onDismissed: (_) => _svc.delete(p.id),
      child: ListTile(
        onTap: () => _openForm(product: p),
        onLongPress: () => _showProductOptions(p),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.redAccent,
              ),
            ),
            if (isLow)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          p.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isLow
              ? 'Stock: ${p.stock}  •  Mín: ${p.minStock}  ⚠ Stock bajo'
              : 'Stock: ${p.stock}  •  Mín: ${p.minStock}',
          style: TextStyle(
            color: isLow ? Colors.red.shade300 : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          '\$${p.price.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: StreamBuilder<List<Product>>(
        stream: _svc.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('No hay productos. Agregá el primero.'),
            );
          }

          final lowCount = items.where((p) => p.isLowStock).length;

          return Column(
            children: [
              if (lowCount > 0)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade900.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '$lowCount producto${lowCount > 1 ? 's' : ''} con stock bajo',
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (_, i) => _buildCard(items[i]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

// ── Form bottom sheet ──────────────────────────────────────────────────────────

class _ProductForm extends StatefulWidget {
  final ProductService svc;
  final Product? product;

  const _ProductForm({required this.svc, this.product});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _minStock;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(
        text: p != null ? p.price.toStringAsFixed(2) : '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '');
    _minStock = TextEditingController(text: p?.minStock.toString() ?? '0');
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _minStock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final price = double.parse(_price.text.trim().replaceAll(',', '.'));
      final stock = int.parse(_stock.text.trim());
      final minStock = int.tryParse(_minStock.text.trim()) ?? 0;

      if (widget.product == null) {
        await widget.svc.create(
          name: name,
          price: price,
          stock: stock,
          minStock: minStock,
        );
      } else {
        await widget.svc.update(
          widget.product!.id,
          name: name,
          price: price,
          stock: stock,
          minStock: minStock,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar producto' : 'Nuevo producto'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre *'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El nombre es requerido'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                decoration: const InputDecoration(
                  labelText: 'Precio *',
                  prefixText: '\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El precio es requerido';
                  }
                  final parsed =
                      double.tryParse(v.trim().replaceAll(',', '.'));
                  if (parsed == null || parsed < 0) {
                    return 'Ingresá un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stock,
                      decoration:
                          const InputDecoration(labelText: 'Stock *'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        if (int.tryParse(v.trim()) == null) {
                          return 'Número entero';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minStock,
                      decoration: const InputDecoration(
                        labelText: 'Stock mínimo',
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null &&
                            v.trim().isNotEmpty &&
                            int.tryParse(v.trim()) == null) {
                          return 'Número entero';
                        }
                        return null;
                      },
                    ),
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(isEdit ? 'Guardar cambios' : 'Agregar producto'),
        ),
      ],
    );
  }
}
