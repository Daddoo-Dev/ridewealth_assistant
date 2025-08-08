import 'package:sentry_flutter/sentry_flutter.dart';

class ErrorTrackingService {
  static Future<void> captureAuthError(
    dynamic error,
    StackTrace? stackTrace, {
    String? authMethod,
    String? userId,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('error_type', 'authentication');
          if (authMethod != null) {
            scope.setTag('auth_method', authMethod);
          }
          if (userId != null) {
            scope.setUser(SentryUser(id: userId));
          }
          if (extra != null) {
            for (final entry in extra.entries) {
              scope.setExtra(entry.key, entry.value);
            }
          }
        },
      );
    } catch (e) {
      print('Failed to capture error in Sentry: $e');
    }
  }

  static Future<void> captureDatabaseError(
    dynamic error,
    StackTrace? stackTrace, {
    String? operation,
    String? table,
    String? userId,
  }) async {
    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('error_type', 'database');
          if (operation != null) {
            scope.setTag('operation', operation);
          }
          if (table != null) {
            scope.setTag('table', table);
          }
          if (userId != null) {
            scope.setUser(SentryUser(id: userId));
          }
        },
      );
    } catch (e) {
      print('Failed to capture database error in Sentry: $e');
    }
  }

  static Future<void> captureUIError(
    dynamic error,
    StackTrace? stackTrace, {
    String? screen,
    String? action,
    String? userId,
  }) async {
    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('error_type', 'ui');
          if (screen != null) {
            scope.setTag('screen', screen);
          }
          if (action != null) {
            scope.setTag('action', action);
          }
          if (userId != null) {
            scope.setUser(SentryUser(id: userId));
          }
        },
      );
    } catch (e) {
      print('Failed to capture UI error in Sentry: $e');
    }
  }

  static Future<void> captureGeneralError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    String? userId,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (context != null) {
            scope.setTag('context', context);
          }
          if (userId != null) {
            scope.setUser(SentryUser(id: userId));
          }
          if (extra != null) {
            for (final entry in extra.entries) {
              scope.setExtra(entry.key, entry.value);
            }
          }
        },
      );
    } catch (e) {
      print('Failed to capture general error in Sentry: $e');
    }
  }

  static Future<void> setUserContext(String userId, {String? email}) async {
    try {
      await Sentry.configureScope((scope) {
        scope.setUser(SentryUser(
          id: userId,
          email: email,
        ));
      });
    } catch (e) {
      print('Failed to set user context in Sentry: $e');
    }
  }

  static Future<void> clearUserContext() async {
    try {
      await Sentry.configureScope((scope) {
        scope.setUser(null);
      });
    } catch (e) {
      print('Failed to clear user context in Sentry: $e');
    }
  }
} 