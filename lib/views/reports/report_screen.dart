import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_settings.dart';
import '../../services/ad_service.dart';
import '../../services/finance_service.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/ui_kit.dart';

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
            return ErrorState(
              message: '${snap.error}',
              onRetry: () => setState(() {}),
            );
          }
          final all = snap.data ?? [];
          final current = _filterMonth(all, _month);
          final settings = context.watch<AppSettingsProvider>();
          final prior =
              _filterMonth(all, DateTime(_month.year, _month.month - 1));

          final income = _sum(current, true);
          final expense = _sum(current, false);
          final net = income - expense;
          final priorIncome = _sum(prior, true);
          final priorExpense = _sum(prior, false);
          final priorNet = priorIncome - priorExpense;
          final errorColor = Theme.of(context).colorScheme.error;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // Month selector + compartir
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _prevMonth,
                  ),
                  Expanded(
                    child: Text(
                      monthFmt.format(_month).toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _isFuture() ? null : _nextMonth,
                  ),
                  const SizedBox(width: 4),
                  MiniAction(
                    icon: Icons.share_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    tooltip: 'Compartir',
                    onPressed: () => _shareReport(
                      income: income,
                      expense: expense,
                      net: net,
                      transactions: current,
                      s: settings,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Summary cards
              Row(
                children: [
                  _statCard('Ingresos', income, Colors.green, settings,
                      icon: Icons.arrow_downward_rounded),
                  const SizedBox(width: 10),
                  _statCard('Gastos', expense, errorColor, settings,
                      icon: Icons.arrow_upward_rounded),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statCard(
                    'Balance',
                    net,
                    net >= 0 ? Colors.green : errorColor,
                    settings,
                    bold: true,
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    'Transacciones',
                    current.length.toDouble(),
                    Theme.of(context).colorScheme.primary,
                    settings,
                    isCount: true,
                    icon: Icons.receipt_long_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Weekly bar chart
              if (current.isNotEmpty) ...[
                const SectionTitle('Ingresos por semana',
                    icon: Icons.bar_chart_rounded),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: _buildBarChart(current, _month, settings),
                ),
                const SizedBox(height: 24),
              ],

              // Top 3 services
              if (current.any((t) => t.isIncome)) ...[
                const SectionTitle('Top servicios / ingresos',
                    icon: Icons.emoji_events_rounded),
                const SizedBox(height: 10),
                _buildTopServices(current, settings),
                const SizedBox(height: 24),
              ],

              // Comparison vs prior month
              const SectionTitle('Comparación con mes anterior',
                  icon: Icons.compare_arrows_rounded),
              const SizedBox(height: 10),
              if (_comparisonUnlocked)
                _buildComparison(income, priorIncome, expense, priorExpense,
                    net, priorNet, settings)
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
    final amber = Colors.amber.shade700;
    return AppCard(
      radius: 18,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: amber.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_rounded, size: 28, color: amber),
          ),
          const SizedBox(height: 12),
          const Text(
            '¿Cómo te fue vs el mes pasado?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Mirá un breve anuncio para desbloquear la comparación',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              AdService().showRewarded(
                onRewarded: () {
                  if (mounted) setState(() => _comparisonUnlocked = true);
                },
              );
            },
            icon: const Icon(Icons.play_circle_rounded, size: 20),
            label: const Text('Ver anuncio'),
            style: FilledButton.styleFrom(
              backgroundColor: amber,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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

  Widget _statCard(String label, double value, Color color,
      AppSettingsProvider s,
      {bool bold = false, bool isCount = false, IconData? icon}) {
    final text = isCount
        ? '${value.toInt()}'
        : s.stealthMode
            ? '••••'
            : '${s.currencySymbol}${value.toStringAsFixed(0)}';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 19,
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

  Widget _buildBarChart(List<FinanceTransaction> txns, DateTime month,
      AppSettingsProvider s) {
    // Semanas del mes: días 1-7, 8-14, 15-21, 22-fin
    final weeks = [
      [1, 7],
      [8, 14],
      [15, 21],
      [22, 31],
    ];
    final labels = ['S1', 'S2', 'S3', 'S4'];
    final values = weeks.map((w) {
      return txns
          .where((t) => t.isIncome && t.date.day >= w[0] && t.date.day <= w[1])
          .fold<double>(0, (s, t) => s + t.amount);
    }).toList();

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) {
      return Text('Sin ingresos este mes.',
          style: TextStyle(color: Theme.of(context).hintColor));
    }

    final primary = Theme.of(context).colorScheme.primary;
    const barH = 100.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final pct = maxVal > 0 ? values[i] / maxVal : 0.0;
        final h = (pct * barH).clamp(4.0, barH);
        final isMax = values[i] == maxVal && values[i] > 0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!s.stealthMode)
                  Text(
                    values[i] > 0
                        ? '${s.currencySymbol}${values[i].toStringAsFixed(0)}'
                        : '',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isMax ? FontWeight.w800 : FontWeight.w500,
                      color: isMax ? primary : Theme.of(context).hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  height: h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primary,
                        primary.withValues(alpha: 0.55),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(labels[i],
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).hintColor)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopServices(
      List<FinanceTransaction> txns, AppSettingsProvider s) {
    final incomes = txns.where((t) => t.isIncome).toList();
    final grouped = <String, double>{};
    for (final t in incomes) {
      grouped[t.description] = (grouped[t.description] ?? 0) + t.amount;
    }
    final sorted = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();

    if (top3.isEmpty) {
      return Text('Sin datos.',
          style: TextStyle(color: Theme.of(context).hintColor));
    }

    const medals = ['🥇', '🥈', '🥉'];
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: top3.asMap().entries.map((e) {
          final entry = e.value;
          final amountStr = s.stealthMode
              ? '••••'
              : '${s.currencySymbol}${entry.value.toStringAsFixed(0)}';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(medals[e.key], style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  amountStr,
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComparison(double income, double priorIncome, double expense,
      double priorExpense, double net, double priorNet, AppSettingsProvider s) {
    final errorColor = Theme.of(context).colorScheme.error;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _compRow('Ingresos', income, priorIncome, Colors.green, s),
          const Divider(height: 18),
          _compRow('Gastos', expense, priorExpense, errorColor, s),
          const Divider(height: 18),
          _compRow('Balance', net, priorNet,
              net >= 0 ? Colors.green : errorColor, s),
        ],
      ),
    );
  }

  Widget _compRow(String label, double current, double prior, Color color,
      AppSettingsProvider s) {
    final diff = current - prior;
    final pct =
        prior == 0 ? (current > 0 ? 100.0 : 0.0) : (diff / prior * 100);
    final isUp = diff >= 0;
    final arrowColor = isUp ? Colors.green : Theme.of(context).colorScheme.error;
    final currentStr = s.stealthMode
        ? '••••'
        : '${s.currencySymbol}${current.toStringAsFixed(0)}';

    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: Theme.of(context).hintColor, fontSize: 13)),
        ),
        Text(currentStr,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(width: 10),
        if (!s.stealthMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: arrowColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${isUp ? '▲' : '▼'} ${pct.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                  color: arrowColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}
