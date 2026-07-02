import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_settings.dart';
import '../../services/finance_service.dart';
import '../../widgets/ui_kit.dart';
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
    final netColor = net >= 0 ? Colors.green : Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: AppCard(
        radius: 18,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _monthFmt.format(now).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const Spacer(),
                Icon(Icons.trending_up_rounded,
                    size: 16, color: Theme.of(context).hintColor),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _summaryCell('Ingresos', income, Colors.green, s),
                const SizedBox(width: 12),
                _summaryCell(
                    'Gastos', expense, Theme.of(context).colorScheme.error, s),
                const SizedBox(width: 12),
                _summaryCell('Balance', net, netColor, s, bold: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCell(String label, double amount, Color color,
      AppSettingsProvider s, {bool bold = false}) {
    final text = s.stealthMode
        ? '••••'
        : '${s.currencySymbol}${amount.toStringAsFixed(0)}';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.9))),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: color,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Transaction card ────────────────────────────────────────────────────────

  Widget _buildCard(FinanceTransaction t, AppSettingsProvider s) {
    final isIncome = t.isIncome;
    final color = isIncome ? Colors.green : Theme.of(context).colorScheme.error;
    final icon =
        isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final amountText = s.stealthMode
        ? '${isIncome ? '+' : '-'}••••'
        : '${isIncome ? '+' : '-'}${s.currencySymbol}${t.amount.toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Dismissible(
        key: Key(t.id),
        direction: DismissDirection.endToStart,
        background: const DismissDeleteBackground(),
        confirmDismiss: (_) => confirmDelete(
          context,
          title: 'Eliminar transacción',
          message:
              '¿Eliminar "${t.description}"? Esta acción no se puede deshacer.',
        ),
        onDismissed: (_) => _svc.delete(t.id),
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dayFmt.format(t.date),
                      style: TextStyle(
                          fontSize: 11, color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
              Text(
                amountText,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            icon: const Icon(Icons.bar_chart_rounded),
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
            return ErrorState(
              message: '${snap.error}',
              onRetry: () => setState(() {}),
            );
          }

          final items = snap.data ?? [];

          return Column(
            children: [
              _buildSummary(items, settings),
              if (items.isEmpty)
                const Expanded(
                  child: EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'Sin transacciones aún',
                    subtitle:
                        'Registrá tu primer ingreso o gasto con el botón de abajo. También podés usar "Cobro rápido" desde el inicio.',
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
                    itemCount: items.length,
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
      ),
    );
  }
}

// ── Form dialog ────────────────────────────────────────────────────────────────

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
    final hint = Theme.of(context).hintColor;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  color: hint.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _typeButton(
                      label: 'Ingreso',
                      icon: Icons.arrow_downward_rounded,
                      selected: isIncome,
                      color: Colors.green,
                      onTap: () =>
                          setState(() => _type = TransactionType.income),
                    ),
                    _typeButton(
                      label: 'Gasto',
                      icon: Icons.arrow_upward_rounded,
                      selected: !isIncome,
                      color: Theme.of(context).colorScheme.error,
                      onTap: () =>
                          setState(() => _type = TransactionType.expense),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amount,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Monto *',
                  prefixText: '$sym ',
                  border: const OutlineInputBorder(),
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
                  if (parsed > 9999999) {
                    return 'El monto es demasiado alto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'La descripción es requerida'
                    : null,
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
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
        FilledButton(
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
            color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? color : Theme.of(context).hintColor,
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : Theme.of(context).hintColor,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
