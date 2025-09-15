import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';

class ErrorTrackingService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static String? _currentUserId;
  static String? _currentUserEmail;

  // Device info cache to avoid repeated calls
  static Map<String, dynamic>? _deviceInfoCache;

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    if (_deviceInfoCache != null) return _deviceInfoCache!;

    try {
      final deviceInfo = <String, dynamic>{
        'platform': Platform.operatingSystem,
        'platform_version': Platform.operatingSystemVersion,
        'app_version': '1.0.18', // Update this from pubspec.yaml version
        'dart_version': Platform.version,
        'is_debug': kDebugMode,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Add platform-specific info
      if (Platform.isAndroid) {
        deviceInfo['android_version'] = Platform.operatingSystemVersion;
      } else if (Platform.isIOS) {
        deviceInfo['ios_version'] = Platform.operatingSystemVersion;
      } else if (Platform.isWindows) {
        deviceInfo['windows_version'] = Platform.operatingSystemVersion;
      } else if (Platform.isMacOS) {
        deviceInfo['macos_version'] = Platform.operatingSystemVersion;
      } else if (Platform.isLinux) {
        deviceInfo['linux_version'] = Platform.operatingSystemVersion;
      }

      _deviceInfoCache = deviceInfo;
      return deviceInfo;
    } catch (e) {
      return {
        'platform': 'unknown',
        'error': 'Failed to get device info: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  static Future<void> captureAuthError(
    dynamic error,
    StackTrace? stackTrace, {
    String? authMethod,
    String? userId,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final tags = <String, dynamic>{
        'error_type': 'authentication',
        if (authMethod != null) 'auth_method': authMethod,
      };

      final context = <String, dynamic>{
        if (extra != null) ...extra,
        'function': 'captureAuthError',
      };

      await _supabase.from('error_tracking').insert({
        'error_type': 'authentication',
        'error_message': error.toString(),
        'stack_trace': stackTrace?.toString(),
        'user_id': userId ?? _currentUserId,
        'platform': deviceInfo['platform'],
        'device_info': deviceInfo,
        'context': context,
        'tags': tags,
      });
    } catch (e) {
      print('Failed to capture auth error in database: $e');
      // Fallback to console logging
      print('AUTH ERROR: $error');
      print('Stack: $stackTrace');
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
      final deviceInfo = await _getDeviceInfo();
      final tags = <String, dynamic>{
        'error_type': 'database',
        if (operation != null) 'operation': operation,
        if (table != null) 'table': table,
      };

      final context = <String, dynamic>{
        'function': 'captureDatabaseError',
        if (operation != null) 'operation': operation,
        if (table != null) 'table': table,
      };

      await _supabase.from('error_tracking').insert({
        'error_type': 'database',
        'error_message': error.toString(),
        'stack_trace': stackTrace?.toString(),
        'user_id': userId ?? _currentUserId,
        'platform': deviceInfo['platform'],
        'device_info': deviceInfo,
        'context': context,
        'tags': tags,
      });
    } catch (e) {
      print('Failed to capture database error in database: $e');
      // Fallback to console logging
      print('DATABASE ERROR: $error');
      print('Stack: $stackTrace');
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
      final deviceInfo = await _getDeviceInfo();
      final tags = <String, dynamic>{
        'error_type': 'ui',
        if (screen != null) 'screen': screen,
        if (action != null) 'action': action,
      };

      final context = <String, dynamic>{
        'function': 'captureUIError',
        if (screen != null) 'screen': screen,
        if (action != null) 'action': action,
      };

      await _supabase.from('error_tracking').insert({
        'error_type': 'ui',
        'error_message': error.toString(),
        'stack_trace': stackTrace?.toString(),
        'user_id': userId ?? _currentUserId,
        'platform': deviceInfo['platform'],
        'device_info': deviceInfo,
        'context': context,
        'tags': tags,
      });
    } catch (e) {
      print('Failed to capture UI error in database: $e');
      // Fallback to console logging
      print('UI ERROR: $error');
      print('Stack: $stackTrace');
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
      final deviceInfo = await _getDeviceInfo();
      final tags = <String, dynamic>{
        'error_type': 'general',
        if (context != null) 'context': context,
      };

      final errorContext = <String, dynamic>{
        'function': 'captureGeneralError',
        if (context != null) 'context': context,
        if (extra != null) ...extra,
      };

      await _supabase.from('error_tracking').insert({
        'error_type': 'general',
        'error_message': error.toString(),
        'stack_trace': stackTrace?.toString(),
        'user_id': userId ?? _currentUserId,
        'platform': deviceInfo['platform'],
        'device_info': deviceInfo,
        'context': errorContext,
        'tags': tags,
      });
    } catch (e) {
      print('Failed to capture general error in database: $e');
      // Fallback to console logging
      print('GENERAL ERROR: $error');
      print('Stack: $stackTrace');
    }
  }

  static Future<void> setUserContext(String userId, {String? email}) async {
    try {
      _currentUserId = userId;
      _currentUserEmail = email;
      
      // Clear device info cache when user changes
      _deviceInfoCache = null;
      
      print('User context set: $userId${email != null ? ' ($email)' : ''}');
    } catch (e) {
      print('Failed to set user context: $e');
    }
  }

  static Future<void> clearUserContext() async {
    try {
      _currentUserId = null;
      _currentUserEmail = null;
      
      // Clear device info cache when user logs out
      _deviceInfoCache = null;
      
      print('User context cleared');
    } catch (e) {
      print('Failed to clear user context: $e');
    }
  }

  // Additional utility methods for custom error tracking

  static Future<void> captureCustomError(
    String errorType,
    String errorMessage, {
    StackTrace? stackTrace,
    String? userId,
    Map<String, dynamic>? context,
    Map<String, dynamic>? tags,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final errorTags = <String, dynamic>{
        'error_type': errorType,
        if (tags != null) ...tags,
      };

      final errorContext = <String, dynamic>{
        'function': 'captureCustomError',
        if (context != null) ...context,
      };

      await _supabase.from('error_tracking').insert({
        'error_type': errorType,
        'error_message': errorMessage,
        'stack_trace': stackTrace?.toString(),
        'user_id': userId ?? _currentUserId,
        'platform': deviceInfo['platform'],
        'device_info': deviceInfo,
        'context': errorContext,
        'tags': errorTags,
      });
    } catch (e) {
      print('Failed to capture custom error in database: $e');
      print('CUSTOM ERROR ($errorType): $errorMessage');
      print('Stack: $stackTrace');
    }
  }

  // Method to get error statistics (for admin dashboard)
  static Future<Map<String, dynamic>?> getErrorStats({
    DateTime? startDate,
    DateTime? endDate,
    String? errorType,
    String? platform,
  }) async {
    try {
      var query = _supabase.from('error_analytics').select();
      
      if (startDate != null) {
        query = query.gte('error_date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('error_date', endDate.toIso8601String().split('T')[0]);
      }
      if (errorType != null) {
        query = query.eq('error_type', errorType);
      }
      if (platform != null) {
        query = query.eq('platform', platform);
      }

      final response = await query;
      return {'stats': response};
    } catch (e) {
      print('Failed to get error stats: $e');
      return null;
    }
  }
}