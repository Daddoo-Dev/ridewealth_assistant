import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../environment.dart';
import 'expense_entry_service.dart';
import 'mileage_entry_service.dart';

/// A confirmation/error message to surface after a voice command runs with
/// no screen in front of the user. [id] is a monotonic counter so repeated
/// identical messages still notify listeners (a plain [ValueNotifier] skips
/// notifying when the new value equals the old one).
class AppActionsFeedback {
  const AppActionsFeedback(this.id, this.message, {required this.isError});

  final int id;
  final String message;
  final bool isError;
}

/// Maps the small set of expense categories realistic to log while driving
/// to the fixed category strings expenses_screen.dart uses. Anything
/// unrecognized (or unspoken) falls back to "Other expenses" for the user
/// to fix up later in-app.
const Map<String, String> _expenseCategoryKeywords = {
  'gas': 'Car and truck expenses',
  'fuel': 'Car and truck expenses',
  'food': 'Meals',
  'meal': 'Meals',
  'meals': 'Meals',
  'lunch': 'Meals',
  'supplies': 'Supplies',
  'supply': 'Supplies',
  'repair': 'Repairs and maintenance',
  'repairs': 'Repairs and maintenance',
  'maintenance': 'Repairs and maintenance',
};

/// Handles the "log a start mileage," "log an end mileage," and "log an
/// expense" Android App Actions voice commands (see
/// android/app/src/main/res/xml/shortcuts.xml). Fulfillment arrives as a deep
/// link on the app's existing verified custom scheme,
/// com.ridewealthassistant.app://, which always launches/resumes the app —
/// [pendingFeedback] is how a result (success or failure) still reaches the
/// user even though there's no screen open at the moment the command runs.
///
/// No-ops entirely while [Environment.enableAppActions] is false — that flag
/// is the single on/off switch for this feature.
class AppActionsService {
  AppActionsService._();

  static final AppActionsService instance = AppActionsService._();

  /// Bumped whenever a mileage voice command is handled. MainScreen listens
  /// and jumps to the Mileage tab on each change.
  final ValueNotifier<int> pendingMileageTabRequests = ValueNotifier<int>(0);

  /// Bumped whenever the "log an expense" voice command is handled.
  /// MainScreen listens and jumps to the Expenses tab on each change.
  final ValueNotifier<int> pendingExpensesTabRequests = ValueNotifier<int>(0);

  /// The latest confirmation/error message to show, if any.
  final ValueNotifier<AppActionsFeedback?> pendingFeedback =
      ValueNotifier<AppActionsFeedback?>(null);

  bool _initialized = false;
  int _feedbackId = 0;

  Future<void> init() async {
    if (!Environment.enableAppActions || _initialized) return;
    _initialized = true;

    final appLinks = AppLinks();

    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleUri(initialUri);
      }
    } catch (e, stack) {
      debugPrint('AppActionsService initial link error: $e');
      Sentry.captureException(e, stackTrace: stack);
    }

    appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (Object e, StackTrace stack) {
        debugPrint('AppActionsService link stream error: $e');
        Sentry.captureException(e, stackTrace: stack);
      },
    );
  }

  void _emitFeedback(String message, {required bool isError}) {
    _feedbackId++;
    pendingFeedback.value = AppActionsFeedback(_feedbackId, message, isError: isError);
  }

  Future<void> _handleUri(Uri uri) async {
    try {
      if (uri.scheme != 'com.ridewealthassistant.app') return;

      if (uri.host == 'mileage' && uri.path == '/start') {
        await _handleLogStartMileage(uri);
      } else if (uri.host == 'mileage' && uri.path == '/end') {
        await _handleLogEndMileage(uri);
      } else if (uri.host == 'expenses' && uri.path == '/log') {
        await _handleLogExpense(uri);
      }
    } catch (e, stack) {
      debugPrint('AppActionsService error handling $uri: $e');
      Sentry.captureException(e, stackTrace: stack);
    }
  }

  Future<void> _handleLogStartMileage(Uri uri) async {
    final mileageValue = int.tryParse(uri.queryParameters['mileage'] ?? '');
    if (mileageValue != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'startMileage',
        jsonEncode({
          'mileage': mileageValue,
          'date': DateTime.now().toIso8601String(),
        }),
      );
    }

    pendingMileageTabRequests.value++;
  }

  Future<void> _handleLogEndMileage(Uri uri) async {
    final endMileage = int.tryParse(uri.queryParameters['mileage'] ?? '');
    if (endMileage == null) {
      _emitFeedback("Couldn't log end mileage — no mileage number heard.", isError: true);
      pendingMileageTabRequests.value++;
      return;
    }

    final stored = await MileageEntryService.loadStoredStartMileage();
    if (stored == null) {
      _emitFeedback('No start mileage on file — log a start mileage first.', isError: true);
      pendingMileageTabRequests.value++;
      return;
    }

    final result = await MileageEntryService.submit(
      startMileage: stored.mileage,
      endMileage: endMileage,
      date: stored.date,
    );

    if (result.isSuccess) {
      _emitFeedback('Trip logged: ${result.totalMiles} miles.', isError: false);
    } else {
      _emitFeedback("Couldn't save mileage: ${result.error}", isError: true);
    }
    pendingMileageTabRequests.value++;
  }

  Future<void> _handleLogExpense(Uri uri) async {
    final amount = double.tryParse(uri.queryParameters['amount'] ?? '');
    if (amount == null) {
      _emitFeedback("Couldn't log expense — no amount heard.", isError: true);
      pendingExpensesTabRequests.value++;
      return;
    }

    final rawCategory = uri.queryParameters['category']?.toLowerCase().trim();
    final category = _expenseCategoryKeywords[rawCategory] ?? 'Other expenses';
    final description = (rawCategory != null && rawCategory.isNotEmpty)
        ? '${rawCategory[0].toUpperCase()}${rawCategory.substring(1)} (voice)'
        : 'Voice logged expense';

    final result = await ExpenseEntryService.submit(
      amount: amount,
      description: description,
      category: category,
      date: DateTime.now(),
    );

    if (result.isSuccess) {
      _emitFeedback('Expense logged: \$${amount.toStringAsFixed(2)} ($category).', isError: false);
    } else {
      _emitFeedback("Couldn't save expense: ${result.error}", isError: true);
    }
    pendingExpensesTabRequests.value++;
  }
}
