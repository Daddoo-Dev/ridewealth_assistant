// Test script for custom error tracking system
// Run this with: dart test_error_tracking.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock the ErrorTrackingService for testing
class ErrorTrackingService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static String? _currentUserId;

  static Future<void> captureAuthError(
    dynamic error,
    StackTrace? stackTrace, {
    String? authMethod,
    String? userId,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final deviceInfo = <String, dynamic>{
        'platform': Platform.operatingSystem,
        'platform_version': Platform.operatingSystemVersion,
        'app_version': '1.0.18',
        'timestamp': DateTime.now().toIso8601String(),
      };

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

      print('✅ Auth error captured successfully');
      print('   Error: $error');
      print('   Auth Method: $authMethod');
      print('   User ID: ${userId ?? _currentUserId}');
    } catch (e) {
      print('❌ Failed to capture auth error: $e');
    }
  }

  static Future<void> captureCustomError(
    String errorType,
    String errorMessage, {
    StackTrace? stackTrace,
    String? userId,
    Map<String, dynamic>? context,
    Map<String, dynamic>? tags,
  }) async {
    try {
      final deviceInfo = <String, dynamic>{
        'platform': Platform.operatingSystem,
        'platform_version': Platform.operatingSystemVersion,
        'app_version': '1.0.18',
        'timestamp': DateTime.now().toIso8601String(),
      };

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

      print('✅ Custom error captured successfully');
      print('   Type: $errorType');
      print('   Message: $errorMessage');
    } catch (e) {
      print('❌ Failed to capture custom error: $e');
    }
  }

  static Future<void> setUserContext(String userId, {String? email}) async {
    _currentUserId = userId;
    print('✅ User context set: $userId${email != null ? ' ($email)' : ''}');
  }

  static Future<void> clearUserContext() async {
    _currentUserId = null;
    print('✅ User context cleared');
  }
}

Future<void> main() async {
  print('🧪 Testing Custom Error Tracking System\n');

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://your-project.supabase.co', // Replace with your actual URL
    anonKey: 'your-anon-key', // Replace with your actual key
  );

  try {
    // Test 1: Set user context
    print('Test 1: Setting user context');
    await ErrorTrackingService.setUserContext('test-user-123', email: 'test@example.com');
    print('');

    // Test 2: Capture auth error
    print('Test 2: Capturing authentication error');
    await ErrorTrackingService.captureAuthError(
      'Invalid callback URI: https://example.com/callback',
      StackTrace.current,
      authMethod: 'google',
      userId: 'test-user-123',
      extra: {
        'callback_uri': 'https://example.com/callback',
        'expected_uri': 'https://yourapp.com/auth/callback',
        'oauth_provider': 'google',
      },
    );
    print('');

    // Test 3: Capture custom error
    print('Test 3: Capturing custom error');
    await ErrorTrackingService.captureCustomError(
      'callback_uri_mismatch',
      'OAuth callback URI does not match configured URI',
      stackTrace: StackTrace.current,
      userId: 'test-user-123',
      context: {
        'oauth_provider': 'google',
        'received_uri': 'https://example.com/callback',
        'expected_uri': 'https://yourapp.com/auth/callback',
        'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
      tags: {
        'severity': 'high',
        'category': 'oauth',
        'provider': 'google',
      },
    );
    print('');

    // Test 4: Clear user context
    print('Test 4: Clearing user context');
    await ErrorTrackingService.clearUserContext();
    print('');

    print('🎉 All tests completed! Check your Supabase error_tracking table for the captured errors.');

  } catch (e) {
    print('❌ Test failed: $e');
  }
}
