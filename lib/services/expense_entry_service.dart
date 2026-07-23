import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of an [ExpenseEntryService.submit] call.
class ExpenseSubmitResult {
  const ExpenseSubmitResult.success() : error = null;
  const ExpenseSubmitResult.failure(this.error);

  final String? error;

  bool get isSuccess => error == null;
}

/// The business-rule validation and Supabase insert shared by the Expenses
/// screen's "Add Expense" button and the "log an expense" voice command, so
/// both paths run identical rules. Callers are responsible for their own
/// UI-level checks (empty fields, login state, amount-string cleanup) before
/// calling this. Only covers new-entry insert — editing an existing expense
/// stays a widget-only concern.
abstract final class ExpenseEntryService {
  static Future<ExpenseSubmitResult> submit({
    required double amount,
    required String description,
    required String category,
    required DateTime date,
    String? notes,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const ExpenseSubmitResult.failure(
        'You must be logged in to submit an expense.',
      );
    }

    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return const ExpenseSubmitResult.failure(
        'Date cannot be more than 1 day in the future.',
      );
    }

    if (amount <= 0) {
      return const ExpenseSubmitResult.failure(
        'Expense amount must be greater than zero.',
      );
    }

    if (amount > 50000) {
      return const ExpenseSubmitResult.failure(
        'Daily expense over \$50,000 seems unreasonable. Please verify.',
      );
    }

    final expenseData = {
      'amount': double.parse(amount.toStringAsFixed(2)),
      'description': description,
      'date': date.toIso8601String(),
      'category': category,
      'user_id': user.id,
      'notes': (notes == null || notes.isEmpty) ? null : notes,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await Supabase.instance.client.from('expenses').insert(expenseData);
      return const ExpenseSubmitResult.success();
    } catch (e, stack) {
      debugPrint('Error adding expense: $e');
      Sentry.captureException(e, stackTrace: stack);
      return const ExpenseSubmitResult.failure(
        'Failed to add expense. Please try again.',
      );
    }
  }
}
