import 'package:flutter/material.dart';

import '../money.dart';
import '../services/quarter_summary_service.dart';

class QuarterTotals extends StatefulWidget {
  @override
  State<QuarterTotals> createState() => _QuarterTotalsState();
}

class _QuarterTotalsState extends State<QuarterTotals> {
  QuarterSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await QuarterSummaryService.loadCurrent();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final summary = _summary;
    if (summary == null) return const SizedBox.shrink();

    final symbol = summary.currencySymbol;
    final after = summary.symbolAfter;
    final unit = summary.distanceUnit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary.label, style: Theme.of(context).textTheme.titleLarge),
              if (summary.offlineOnly) ...[
                const SizedBox(height: 8),
                Text(
                  'Showing entries saved on this phone. Totals will include the rest when you are back online.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              _line(context, 'Income', Money.format(summary.income, symbol, after)),
              _line(context, 'Expenses', Money.format(summary.expenses, symbol, after)),
              _line(context, 'Distance', '${summary.distance} $unit'),
              _line(
                context,
                'Distance deduction',
                Money.format(summary.estimate.distanceDeduction, symbol, after),
              ),
              const SizedBox(height: 12),
              Text('Set aside', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _setAside(
                context,
                'Income only',
                summary.estimate.onIncome.primary,
                summary.estimate.onIncome.secondary,
                symbol,
                summary.symbolAfter,
              ),
              _setAside(
                context,
                'After expenses',
                summary.estimate.afterExpenses.primary,
                summary.estimate.afterExpenses.secondary,
                symbol,
                summary.symbolAfter,
              ),
              _setAside(
                context,
                'After expenses and distance',
                summary.estimate.afterDistance.primary,
                summary.estimate.afterDistance.secondary,
                symbol,
                summary.symbolAfter,
              ),
              if (summary.distanceRate == 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Set a distance rate on the Taxes tab to include it.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _setAside(
    BuildContext context,
    String label,
    double primary,
    double secondary,
    String symbol,
    bool after,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            'Primary ${Money.format(primary, symbol, after)} · Secondary ${Money.format(secondary, symbol, after)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
