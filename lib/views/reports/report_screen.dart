import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_settings.dart';
import '../../services/ad_service.dart';
import '../../services/finance_service.dart';
import '../../widgets/ad_banner.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _svc = FinanceService();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _comparisonUnlocked = false;

  void _shareReport({
    required double income,
    required double expense,
    required double net,
    required List<FinanceTransaction> transactions,
    required AppSettingsProvider s,
  }) {
    final monthFmt = DateFormat('MMMM yyyy', 'es');
    final sym = s.currencySymbol;
    final buf = StringBuffer();
    buf.writeln('📊 Reporte BizPulse — ${monthFmt.format(_month).toUpperCase()}');
    buf.writeln();
    buf.writeln('💚 Ingresos:  $sym ${income.toStringAsFixed(0)}');
    buf.writeln('🔴 Gastos:    $sym ${expense.toStringAsFixed(0)}');
    buf.writeln('📈 Balance:   $sym ${net.toStringAsFixed(0)}');
    buf.writeln('🔢 Transacciones: ${transactions.length}');
    buf.writeln();
    buf.writeln('— Generado con BizPulse');
    Share.share(buf.toString());
  }

  void _prevMonth() => setState(() =>
      _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    if (next.isAfter(DateTime.now())) return;
    setState(() => _month = next);
  }

  bool _isFuture() {
    final now = DateTime.now();
    final next = DateTime(_month.year, _month.month + 1);
    return next.isAfter(DateTime(now.year, now.month + 1));
  }

  @override
  Widget build(BuildContext context) {
    final monthFmt = DateFormat('MMMM yyyy', 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte mensual'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<FinanceTransaction>>(
        stream: _svc.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final all = snap.data ?? [];
          final current = _filterMonth(all, _month);
          final settings = context.watch<AppSettingsProvider>();
          final prior = _filterMonth(
              all, DateTime(_month.year, _month.month - 1));

          final income = _sum(current, true);
          final expense = _sum(current, false);
          final net = income - expense;
          final priorIncome = _sum(prior, true);
          final priorExpense = _sum(prior, false);
          final priorNet = priorIncome - priorExpense;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              // Botón compartir
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _shareReport(
                    income: income,
                    expense: expense,
                    net: net,
                    transactions: current,
                    s: settings,
                  ),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Compartir'),
                ),
              ),
              // Month selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    monthFmt.format(_month).toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right,
                        color: _isFuture() ? Colors.white24 : null),
                    onPressed: _isFuture() ? null : _nextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Summary cards
              Row(
                children: [
                  _card('Ingresos', income, Colors.green, settings),
                  const SizedBox(width: 8),
                  _card('Gastos', expense, Colors.red, settings),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _card(
                    'Balance',
                    net,
                    net >= 0 ? Colors.greenAccent : Colors.redAccent,
                    settings,
                    bold: true,
                  ),
                  const SizedBox(width: 8),
                  _card('Transacciones', current.length.toDouble(),
                      Colors.blueAccent, settings,
                      isCount: true),
                ],
              ),

              const SizedBox(height: 20),

              // Weekly bar chart
              if (current.isNotEmpty) ...[
                const Text('Ingresos por semana',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                _buildBarChart(current, _month, settings),
                const SizedBox(height: 20),
              ],

              // Top 3 services
              if (current.any((t) => t.isIncome)) ...[
                const Text('Top servicios / ingresos',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                _buildTopServices(current, settings),
                const SizedBox(height: 20),
              ],

              // Comparison vs prior month
              const Text('Comparación con mes anterior',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              if (_comparisonUnlocked)
                _buildComparison(
                    income, priorIncome, expense, priorExpense, net, priorNet,
                    settings)
              else
                _lockedComparison(),
              const SizedBox(height: 24),
              const Center(child: AdBannerWidget()),
            ],
          );
        },
      ),
    );
  }

  Widget _lockedComparison() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 36, color: Colors.white30),
          const SizedBox(height: 12),
          const Text(
            '¿Cómo te fue vs el mes pasado?',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mirá un breve anuncio para desbloquear',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              AdService().showRewarded(
                onRewarded: () {
                  if (mounted) setState(() => _comparisonUnlocked = true);
                },
              );
            },
            icon: const Icon(Icons.play_circle_outline, size: 20),
            label: const Text('Ver anuncio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<FinanceTransaction> _filterMonth(
      List<FinanceTransaction> all, DateTime m) {
    return all
        .where((t) => t.date.year == m.year && t.date.month == m.month)
        .toList();
  }

  double _sum(List<FinanceTransaction> list, bool income) =>
      list.where((t) => t.isIncome == income).fold(0, (s, t) => s + t.amount);

  // ── Widgets ─────────────────────────────────────────────────────────────────

  Widget _card(String label, double value, Color color,
      AppSettingsProvider s, {bool bold = false, bool isCount = false}) {
    final text = isCount
        ? '${value.toInt()}'
        : s.stealthMode
            ? '••••'
            : '${s.currencySymbol}${value.toStringAsFixed(0)}';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<FinanceTransaction> txns, DateTime month,
      AppSettingsProvider s) {
    // Split into 4 pseudo-weeks: days 1-7, 8-14, 15-21, 22-end
    final weeks = [
      [1, 7],
      [8, 14],
      [15, 21],
      [22, 31],
    ];
    final labels = ['S1', 'S2', 'S3', 'S4'];
    final values = weeks.map((w) {
      return txns
          .where((t) =>
              t.isIncome &&
              t.date.day >= w[0] &&
              t.date.day <= w[1])
          .fold<double>(0, (s, t) => s + t.amount);
    }).toList();

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) {
      return const Text('Sin ingresos este mes.',
          style: TextStyle(color: Colors.white54));
    }

    final barH = 100.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final pct = maxVal > 0 ? values[i] / maxVal : 0.0;
        final h = (pct * barH).clamp(4.0, barH);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!s.stealthMode)
                  Text(
                    values[i] > 0
                        ? '${s.currencySymbol}${values[i].toStringAsFixed(0)}'
                        : '',
                    style: const TextStyle(fontSize: 9, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 2),
                Container(
                  height: h,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(labels[i],
                    style: const TextStyle(
                        fontSize: 10, color: Colors.white54)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopServices(List<FinanceTransaction> txns,
      AppSettingsProvider s) {
    final incomes = txns.where((t) => t.isIncome).toList();
    final grouped = <String, double>{};
    for (final t in incomes) {
      grouped[t.description] = (grouped[t.description] ?? 0) + t.amount;
    }
    final sorted = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();

    if (top3.isEmpty) {
      return const Text('Sin datos.',
          style: TextStyle(color: Colors.white54));
    }

    return Column(
      children: top3.asMap().entries.map((e) {
        final entry = e.value;
        final medals = ['🥇', '🥈', '🥉'];
        final amountStr = s.stealthMode
            ? '••••'
            : '${s.currencySymbol}${entry.value.toStringAsFixed(0)}';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Text(medals[e.key],
              style: const TextStyle(fontSize: 22)),
          title: Text(entry.key,
              style: const TextStyle(fontSize: 13)),
          trailing: Text(amountStr,
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }

  Widget _buildComparison(double income, double priorIncome, double expense,
      double priorExpense, double net, double priorNet,
      AppSettingsProvider s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _compRow('Ingresos', income, priorIncome, Colors.green, s),
          const Divider(height: 16),
          _compRow('Gastos', expense, priorExpense, Colors.red, s),
          const Divider(height: 16),
          _compRow(
              'Balance', net, priorNet,
              net >= 0 ? Colors.greenAccent : Colors.redAccent, s),
        ],
      ),
    );
  }

  Widget _compRow(String label, double current, double prior, Color color,
      AppSettingsProvider s) {
    final diff = current - prior;
    final pct = prior == 0
        ? (current > 0 ? 100.0 : 0.0)
        : (diff / prior * 100);
    final arrow = diff >= 0 ? '▲' : '▼';
    final arrowColor = diff >= 0 ? Colors.greenAccent : Colors.redAccent;
    final currentStr = s.stealthMode
        ? '••••'
        : '${s.currencySymbol}${current.toStringAsFixed(0)}';
    final diffStr = s.stealthMode
        ? ''
        : '$arrow ${pct.abs().toStringAsFixed(1)}%';

    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ),
        Text(currentStr,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 8),
        if (!s.stealthMode)
          Text(diffStr,
              style: TextStyle(color: arrowColor, fontSize: 11)),
      ],
    );
  }
}
