import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of a [MileageEntryService.submit] call.
class MileageSubmitResult {
  const MileageSubmitResult.success(this.totalMiles) : error = null;
  const MileageSubmitResult.failure(this.error) : totalMiles = null;

  final int? totalMiles;
  final String? error;

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

    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return const MileageSubmitResult.failure(
        'Date cannot be more than 1 day in the future.',
      );
    }

    if (startMileage < 0 || endMileage < 0) {
      return const MileageSubmitResult.failure('Mileage cannot be negative.');
    }

    if (startMileage > 999999 || endMileage > 999999) {
      return const MileageSubmitResult.failure(
        'Mileage values are unreasonably high.',
      );
    }

    if (endMileage <= startMileage) {
      return const MileageSubmitResult.failure(
        'End mileage must be greater than start mileage.',
      );
    }

    final totalMiles = endMileage - startMileage;
    if (totalMiles > 1000) {
      return const MileageSubmitResult.failure(
        'Daily mileage over 1000 miles/km seems unreasonable. Please verify.',
      );
    }

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
      await Supabase.instance.client.from('mileage').insert(mileageData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('startMileage');
      return MileageSubmitResult.success(totalMiles);
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
