import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'grace_period_service.dart';
import 'remote_insert.dart';

class IncomeSubmitResult {
  const IncomeSubmitResult.saved() : error = null, queued = false;
  const IncomeSubmitResult.queued() : error = null, queued = true;
  const IncomeSubmitResult.failure(this.error) : queued = false;

  final String? error;
  final bool queued;

  bool get isSuccess => error == null;
}

abstract final class IncomeEntryService {
  static Future<IncomeSubmitResult> submit({
    required double amount,
    required String description,
    required DateTime date,
    String? notes,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const IncomeSubmitResult.failure(
        'You must be logged in to submit income.',
      );
    }

    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return const IncomeSubmitResult.failure(
        'Date cannot be more than 1 day in the future.',
      );
    }

    if (amount <= 0) {
      return const IncomeSubmitResult.failure(
        'Income amount must be greater than zero.',
      );
    }

    if (amount > 100000) {
      return const IncomeSubmitResult.failure(
        'Daily income over \$100,000 seems unreasonable. Please verify.',
      );
    }

    final incomeData = {
      'amount': double.parse(amount.toStringAsFixed(2)),
      'description': description,
      'date': date.toIso8601String(),
      'user_id': user.id,
      'notes': (notes == null || notes.isEmpty) ? null : notes,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final result = await RemoteInsert.insert(table: 'income', row: incomeData);
      await GracePeriodService.recordUsage();
      if (result.queued) return const IncomeSubmitResult.queued();
      return const IncomeSubmitResult.saved();
    } catch (error, stack) {
      debugPrint('Error adding income: $error');
      await Sentry.captureException(error, stackTrace: stack);
      return const IncomeSubmitResult.failure(
        'Failed to add income. Please try again.',
      );
    }
  }
}
