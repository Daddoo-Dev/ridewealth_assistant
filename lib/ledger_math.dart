/// Shared ledger math for the tax screen, the home totals, and the yearly export.
class QuarterPeriod {
  const QuarterPeriod({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;

  static QuarterPeriod containing(DateTime date) {
    final quarter = ((date.month - 1) ~/ 3) + 1;
    final startMonth = (quarter - 1) * 3 + 1;
    final start = DateTime(date.year, startMonth, 1);
    final end = DateTime(date.year, startMonth + 3, 0, 23, 59, 59);
    return QuarterPeriod(
      start: start,
      end: end,
      label: 'Q$quarter ${date.year}',
    );
  }
}

class SetAside {
  const SetAside({
    required this.base,
    required this.primary,
    required this.secondary,
  });

  final double base;
  final double primary;
  final double secondary;
}

class SetAsideEstimate {
  const SetAsideEstimate({
    required this.onIncome,
    required this.afterExpenses,
    required this.afterDistance,
    required this.distanceDeduction,
  });

  final SetAside onIncome;
  final SetAside afterExpenses;
  final SetAside afterDistance;
  final double distanceDeduction;

  static SetAsideEstimate compute({
    required double income,
    required double expenses,
    required int distance,
    required double distanceRate,
    required double primaryRate,
    required double secondaryRate,
    required bool applyDistanceToSecondary,
  }) {
    final deduction = distance * distanceRate;
    final afterExpensesBase = income - expenses;
    final afterDistanceBase = afterExpensesBase - deduction;
    final secondaryDistanceBase =
        applyDistanceToSecondary ? afterDistanceBase : afterExpensesBase;

    return SetAsideEstimate(
      distanceDeduction: deduction,
      onIncome: SetAside(
        base: income,
        primary: income * primaryRate,
        secondary: income * secondaryRate,
      ),
      afterExpenses: SetAside(
        base: afterExpensesBase,
        primary: afterExpensesBase * primaryRate,
        secondary: afterExpensesBase * secondaryRate,
      ),
      afterDistance: SetAside(
        base: afterDistanceBase,
        primary: afterDistanceBase * primaryRate,
        secondary: secondaryDistanceBase * secondaryRate,
      ),
    );
  }
}

double sumAmounts(Iterable<Map<String, dynamic>> rows) {
  return rows.fold(0.0, (total, row) {
    return total + ((row['amount'] ?? 0) as num).toDouble();
  });
}

int distanceUnits(num start, num end) => (end - start).round();

int sumDistance(Iterable<Map<String, dynamic>> rows) {
  return rows.fold(0, (total, row) {
    final start = (row['start_mileage'] ?? 0) as num;
    final end = (row['end_mileage'] ?? 0) as num;
    return total + distanceUnits(start, end);
  });
}

/// Empty input clears the rate. A comma is accepted as the decimal mark.
/// Values outside 0 to 5.00 are rejected.
double? parseDistanceRate(String text) {
  final cleaned = text.trim().replaceAll(',', '.');
  if (cleaned.isEmpty) return 0;
  final value = double.tryParse(cleaned);
  if (value == null || value < 0 || value > 5) return null;
  return (value * 100).round() / 100;
}

bool descriptionIsSecondaryPayment(String description) {
  final text = description.toLowerCase();
  return text.contains('state') ||
      text.contains('secondary') ||
      text.contains('regional');
}

List<List<dynamic>> buildFinancialExportRows({
  required List<Map<String, dynamic>> expenses,
  required List<Map<String, dynamic>> income,
  required List<Map<String, dynamic>> mileage,
  required double distanceRate,
  required List<String> expenseCategories,
}) {
  final totalIncome = sumAmounts(income);
  final totalExpenses = sumAmounts(expenses);
  final deduction = sumDistance(mileage) * distanceRate;
  final netIncome = totalIncome - totalExpenses - deduction;

  final categoryTotals = <String, double>{
    for (final category in expenseCategories) category: 0.0,
  };
  var primaryPayments = 0.0;
  var secondaryPayments = 0.0;

  for (final expense in expenses) {
    final category = (expense['category'] ?? 'Other expenses').toString();
    final amount = ((expense['amount'] ?? 0) as num).toDouble();
    if (category == 'Estimated Tax Payment') {
      final description = (expense['description'] ?? '').toString();
      if (descriptionIsSecondaryPayment(description)) {
        secondaryPayments += amount;
      } else {
        primaryPayments += amount;
      }
    } else {
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
    }
  }

  final rows = <List<dynamic>>[
    ['Total Income', totalIncome.toStringAsFixed(2)],
    ['Total Expenses', totalExpenses.toStringAsFixed(2)],
    ['Total distance deduction', deduction.toStringAsFixed(2)],
    ['Net Income', netIncome.toStringAsFixed(2)],
    [],
    ['Expense Categories'],
  ];

  for (final category in expenseCategories) {
    if (category == 'Estimated Tax Payment') continue;
    rows.add([category, (categoryTotals[category] ?? 0.0).toStringAsFixed(2)]);
  }

  rows.add([]);
  rows.add(['Estimated payments (primary)', primaryPayments.toStringAsFixed(2)]);
  rows.add(
      ['Estimated payments (secondary)', secondaryPayments.toStringAsFixed(2)]);
  return rows;
}
