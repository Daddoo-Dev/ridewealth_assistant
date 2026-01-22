import 'package:flutter/foundation.dart';

class FeatureFlags {
  static final Map<String, dynamic> _flags = {};
  
  // Default values (used if Supabase is unreachable)
  static const defaults = {
    'subscriptions_enabled': false,
    'subscription_check_enabled': false,
    'subscription_required_screen_enabled': false,
    'store_redirect_enabled': false,
  };
  
  // Override for testing - set to false to bypass subscription checks
  static const bool _bypassSubscriptionCheck = true;

  static Future<void> initialize() async {
    // Use defaults (feature_flags table doesn't exist)
    _flags.addAll(defaults);
    
    // In debug mode, override with development settings
    // Note: _bypassSubscriptionCheck takes precedence over these settings
    if (kDebugMode && !_bypassSubscriptionCheck) {
      _flags['subscriptions_enabled'] = true;
      _flags['subscription_check_enabled'] = true;
      _flags['subscription_required_screen_enabled'] = true;
      _flags['store_redirect_enabled'] = false;
    }
  }

  static bool get subscriptionsEnabled => 
      _flags['subscriptions_enabled'] ?? defaults['subscriptions_enabled']!;
      
  static bool get subscriptionCheckEnabled =>
      !_bypassSubscriptionCheck && subscriptionsEnabled && (_flags['subscription_check_enabled'] ?? defaults['subscription_check_enabled']!);
      
  static bool get subscriptionRequiredScreenEnabled =>
      subscriptionsEnabled && (_flags['subscription_required_screen_enabled'] ?? defaults['subscription_required_screen_enabled']!);
      
  static bool get storeRedirectEnabled =>
      subscriptionsEnabled && (_flags['store_redirect_enabled'] ?? defaults['store_redirect_enabled']!);
} 