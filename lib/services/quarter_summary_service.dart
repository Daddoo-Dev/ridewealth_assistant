import 'package:supabase_flutter/supabase_flutter.dart';

import '../ledger_math.dart';
import 'pending_entry_queue.dart';
import 'user_settings.dart';

class QuarterSummary {
  const QuarterSummary({
    required this.label,
    required this.income,
    required this.expenses,
    required this.distance,
    required this.distanceRate,
    required this.estimate,
    required this.currencySymbol,
    required this.symbolAfter,
    required this.distanceUnit,
    required this.offlineOnly,
  });

  final String label;
  final double income;
  final double expenses;
  final int distance;
  final double distanceRate;
  final SetAsideEstimate estimate;
  final String currencySymbol;
  final bool symbolAfter;
  final String distanceUnit;
  final bool offlineOnly;
}

abstract final class QuarterSummaryService {
  static Future<QuarterSummary?> loadCurrent() async {
    final settings = await UserSettings.load();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final period = QuarterPeriod.containing(DateTime.now());
    var offlineOnly = false;
    List<Map<String, dynamic>> income = [];
    List<Map<String, dynamic>> expenses = [];
    List<Map<String, dynamic>> mileage = [];

    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('income')
            .select()
            .eq('user_id', user.id)
            .gte('date', period.start.toIso8601String())
            .lte('date', period.end.toIso8601String()),
        Supabase.instance.client
            .from('expenses')
            .select()
            .eq('user_id', user.id)
            .gte('date', period.start.toIso8601String())
            .lte('date', period.end.toIso8601String()),
        Supabase.instance.client
            .from('mileage')
            .select()
            .eq('user_id', user.id)
            .gte('start_date', period.start.toIso8601String())
            .lte('start_date', period.end.toIso8601String()),
      ]);
      income = _maps(results[0]);
      expenses = _maps(results[1]);
      mileage = _maps(results[2]);
    } catch (_) {
      offlineOnly = true;
    }

    income = await _withPending(income, 'income', 'date', period);
    expenses = await _withPending(expenses, 'expenses', 'date', period);
    mileage = await _withPending(mileage, 'mileage', 'start_date', period);

    final incomeTotal = sumAmounts(income);
    final expenseTotal = sumAmounts(expenses);
    final distance = sumDistance(mileage);
    final estimate = SetAsideEstimate.compute(
      income: incomeTotal,
      expenses: expenseTotal,
      distance: distance,
      distanceRate: settings.distanceRate,
      primaryRate: settings.primaryRate,
      secondaryRate: settings.secondaryRate,
      applyDistanceToSecondary: settings.applyDistanceToSecondary,
    );

    return QuarterSummary(
      label: period.label,
      income: incomeTotal,
      expenses: expenseTotal,
      distance: distance,
      distanceRate: settings.distanceRate,
      estimate: estimate,
      currencySymbol: settings.currencySymbol,
      symbolAfter: settings.symbolAfter,
      distanceUnit: settings.distanceUnit,
      offlineOnly: offlineOnly,
    );
  }

  static Future<List<Map<String, dynamic>>> _withPending(
    List<Map<String, dynamic>> remote,
    String table,
    String field,
    QuarterPeriod period,
  ) async {
    final merged = await PendingEntryQueue.merge(table, remote);
    final pending = _within(
      merged.where((row) => row['pending_sync'] == true).toList(),
      field,
      period,
    );
    final saved = merged.where((row) => row['pending_sync'] != true).toList();
    return [...pending, ...saved];
  }

  static List<Map<String, dynamic>> _maps(dynamic response) {
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  static List<Map<String, dynamic>> _within(
    List<Map<String, dynamic>> rows,
    String field,
    QuarterPeriod period,
  ) {
    return rows.where((row) {
      final value = row[field];
      if (value == null) return false;
      final date = value is DateTime ? value : DateTime.tryParse(value.toString());
      if (date == null) return false;
      return !date.isBefore(period.start) && !date.isAfter(period.end);
    }).toList();
  }
}
