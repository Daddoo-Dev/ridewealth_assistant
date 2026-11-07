import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mileage_rules.dart';
import 'grace_period_service.dart';
import 'remote_insert.dart';

/// Result of a [MileageEntryService.submit] call.
class MileageSubmitResult {
  const MileageSubmitResult.saved(this.totalMiles)
      : error = null,
        queued = false;
  const MileageSubmitResult.queued(this.totalMiles)
      : error = null,
        queued = true;
  const MileageSubmitResult.failure(this.error)
      : totalMiles = null,
        queued = false;

  final int? totalMiles;
  final String? error;
  final bool queued;

  bool get isSuccess => error == null;
}

/// The business-rule validation and Supabase write shared by the Mileage
/// screen's "Submit Mileage" button and the "log an end mileage" voice
/// command, so both paths run identical rules. Callers are responsible for
/// their own UI-level checks (empty fields, login state, text parsing)
/// before calling this.
abstract final class MileageEntryService {
  static Future<MileageSubmitResult> submit({
    required int startMileage,
    required int endMileage,
    required DateTime date,
    String? notes,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const MileageSubmitResult.failure(
        'You must be logged in to submit mileage.',
      );
    }

    final ruleError = MileageRules.validate(
      startMileage: startMileage,
      endMileage: endMileage,
      date: date,
    );
    if (ruleError != null) {
      return MileageSubmitResult.failure(ruleError);
    }

    final totalMiles = endMileage - startMileage;

    final mileageData = {
      'start_mileage': startMileage,
      'end_mileage': endMileage,
      'start_date': date.toIso8601String(),
      'end_date': date.toIso8601String(),
      'user_id': user.id,
      'notes': (notes == null || notes.isEmpty) ? null : notes,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final result =
          await RemoteInsert.insert(table: 'mileage', row: mileageData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('startMileage');
      await GracePeriodService.recordUsage();
      if (result.queued) return MileageSubmitResult.queued(totalMiles);
      return MileageSubmitResult.saved(totalMiles);
    } catch (e, stack) {
      debugPrint('Error submitting mileage: $e');
      Sentry.captureException(e, stackTrace: stack);
      return const MileageSubmitResult.failure(
        'Failed to submit mileage. Please try again.',
      );
    }
  }

  /// Reads the start mileage/date previously saved via the "Save Mileage"
  /// button or the "log a start mileage" voice command.
  static Future<({int mileage, DateTime date})?> loadStoredStartMileage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('startMileage');
    if (stored == null) return null;
    final data = jsonDecode(stored) as Map<String, dynamic>;
    return (
      mileage: data['mileage'] as int,
      date: DateTime.parse(data['date'] as String),
    );
  }
}
