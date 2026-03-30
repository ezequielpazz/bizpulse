import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_settings.dart';
import '../../services/finance_service.dart';
import '../reports/report_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _svc = FinanceService();
  final _monthFmt = DateFormat('MMMM yyyy', 'es');
  final _dayFmt = DateFormat('dd/MM/yyyy');

  // ── Summary header ──────────────────────────────────────────────────────────

  Widget _buildSummary(List<FinanceTransaction> all, AppSettingsProvider s) {
    final now = DateTime.now();
    final thisMonth = all.where(
      (t) => t.date.year == now.year && t.date.month == now.month,
    );

    double income = 0;
    double expense = 0;
    for (final t in thisMonth) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    final net = income - expense;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _monthFmt.format(now).toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryCell('Ingresos', income, Colors.green, s),
              const SizedBox(width: 12),
              _summaryCell('Gastos', expense, Colors.red, s),
              const SizedBox(width: 12),
              _summaryCell(
                'Balance',
                net,
                net >= 0 ? Colors.greenAccent : Colors.redAccent,
                s,
                bold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(String label, double amount, Color color,
      AppSettingsProvider s, {bool bold = false}) {
    final text = s.stealthMode
        ? '••••'
        : '${s.currencySymbol}${amount.toStringAsFixed(2)}';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Transaction card ────────────────────────────────────────────────────────

  Widget _buildCard(FinanceTransaction t, AppSettingsProvider s) {
    final isIncome = t.isIncome;
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
    final amountText = s.stealthMode
        ? '${isIncome ? '+' : '-'}••••'
        : '${isIncome ? '+' : '-'}${s.currencySymbol}${t.amount.toStringAsFixed(2)}';

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade900,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(t),
      onDismissed: (_) => _svc.delete(t.id),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          t.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          _dayFmt.format(t.date),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          amountText,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ── Delete confirmation ─────────────────────────────────────────────────────

  Future<bool> _confirmDelete(FinanceTransaction t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar transacción'),
        content: Text(
            '¿Eliminar "${t.description}"? Esta acción no se puede deshacer.'),
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

  // ── FAB ─────────────────────────────────────────────────────────────────────

  Future<void> _openForm() async {
    await showDialog(
      context: context,
      builder: (_) => _TransactionForm(svc: _svc),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganancias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Ver reporte',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<FinanceTransaction>>(
        stream: _svc.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text('Error: ${snap.error}',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final items = snap.data ?? [];

          return Column(
            children: [
              _buildSummary(items, settings),
              if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.white24),
                        const SizedBox(height: 12),
                        const Text('Sin transacciones aún',
                            style: TextStyle(fontSize: 16, color: Colors.white54)),
                        const SizedBox(height: 4),
                        const Text('Registrá tu primer ingreso o gasto',
                            style: TextStyle(fontSize: 13, color: Colors.white30)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (_, i) => _buildCard(items[i], settings),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Nueva transacción'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

// ── Form bottom sheet ──────────────────────────────────────────────────────────

class _TransactionForm extends StatefulWidget {
  final FinanceService svc;

  const _TransactionForm({required this.svc});

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  TransactionType _type = TransactionType.income;
  DateTime _date = DateTime.now();
  bool _saving = false;

  final _dayFmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.svc.create(
        type: _type,
        amount: double.parse(_amount.text.trim().replaceAll(',', '.')),
        description: _description.text.trim(),
        date: _date,
      );
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
    final isIncome = _type == TransactionType.income;
    final sym = context.read<AppSettingsProvider>().currencySymbol;

    return AlertDialog(
      title: const Text('Nueva transacción'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Income / Expense toggle
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _typeButton(
                      label: 'Ingreso',
                      icon: Icons.arrow_downward,
                      selected: isIncome,
                      color: Colors.green,
                      onTap: () =>
                          setState(() => _type = TransactionType.income),
                    ),
                    _typeButton(
                      label: 'Gasto',
                      icon: Icons.arrow_upward,
                      selected: !isIncome,
                      color: Colors.red,
                      onTap: () =>
                          setState(() => _type = TransactionType.expense),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amount,
                decoration: InputDecoration(
                  labelText: 'Monto *',
                  prefixText: '$sym ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El monto es requerido';
                  }
                  final parsed =
                      double.tryParse(v.trim().replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresá un monto válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _description,
                decoration:
                    const InputDecoration(labelText: 'Descripción *'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'La descripción es requerida'
                    : null,
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(_dayFmt.format(_date)),
                ),
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
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _typeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: color, width: 1.5)
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? color : Colors.grey, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : Colors.grey,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
