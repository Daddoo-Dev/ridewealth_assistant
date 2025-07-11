import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureFlags {
  static final Map<String, dynamic> _flags = {};
  
  // Default values (used if Supabase is unreachable)
  static const defaults = {
    'subscriptions_enabled': false,
    'subscription_check_enabled': false,
    'subscription_required_screen_enabled': false,
    'store_redirect_enabled': false,
  };

  static Future<void> initialize() async {
    try {
      // Try to fetch feature flags from Supabase
      final response = await Supabase.instance.client
          .from('feature_flags')
          .select()
          .single();
      
      _flags.addAll(response);
    } catch (e) {
      print('Error loading feature flags from Supabase: $e');
      // Fall back to defaults
      _flags.addAll(defaults);
    }
    
    // In debug mode, override with development settings
    if (kDebugMode) {
      _flags['subscriptions_enabled'] = true;
      _flags['subscription_check_enabled'] = true;
      _flags['subscription_required_screen_enabled'] = true;
      _flags['store_redirect_enabled'] = false;
    }
  }

  static bool get subscriptionsEnabled => 
      _flags['subscriptions_enabled'] ?? defaults['subscriptions_enabled']!;
      
  static bool get subscriptionCheckEnabled =>
      subscriptionsEnabled && (_flags['subscription_check_enabled'] ?? defaults['subscription_check_enabled']!);
      
  static bool get subscriptionRequiredScreenEnabled =>
      subscriptionsEnabled && (_flags['subscription_required_screen_enabled'] ?? defaults['subscription_required_screen_enabled']!);
      
  static bool get storeRedirectEnabled =>
      subscriptionsEnabled && (_flags['store_redirect_enabled'] ?? defaults['store_redirect_enabled']!);
} 