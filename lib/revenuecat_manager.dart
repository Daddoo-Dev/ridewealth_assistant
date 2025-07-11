import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, kDebugMode;

class RevenueCatManager {
  // Product IDs from IAP data (for future use)
  // static const String _iosProductId = '1000001';
  // static const String _androidProductId = 'com.ridewealthassistant.subscribe.annual:annualsubscription';
  
  // RevenueCat API Keys (for future use if needed)
  // static const String _iosApiKey = 'appl_LGiUYfDhJkeeChtCBEyowyUORDA';
  // static const String _androidApiKey = 'goog_nCTparCRddssvqMQrcRlaCjrEyR';
  static final supabase = Supabase.instance.client;

  /// Initialize RevenueCat
  static Future<void> initialize() async {
    try {
      if (kIsWeb) return;
      if (kDebugMode) {
        print('RevenueCat debug mode enabled');
      }
      // Initialize RevenueCat if needed in the future
      print('RevenueCat initialization completed');
      
      // Sync user with Supabase if authenticated
      final user = supabase.auth.currentUser;
      if (user != null) {
        await _syncUserToSupabase(user.id);
      }
    } catch (e) {
      print('Error initializing RevenueCat: $e');
    }
  }

  /// Check if user has active subscription
  static Future<bool> isSubscriptionActive() async {
    try {
      if (kIsWeb) return await _checkSupabaseSubscription();
      
      // For mobile platforms, check Supabase subscription status
      return await _checkSupabaseSubscription();
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  /// Get available offerings (subscription packages)
  static Future<Map<String, dynamic>?> getCurrentOffering() async {
    try {
      if (kIsWeb) return null;
      
      // Return mock offerings for now
      return {
        'identifier': 'default',
        'availablePackages': [
          {
            'identifier': 'monthly',
            'packageType': 'MONTHLY',
            'product': {
              'identifier': 'premium_monthly',
              'price': 9.99,
              'priceString': '\$9.99/month',
            },
          },
          {
            'identifier': 'yearly',
            'packageType': 'ANNUAL',
            'product': {
              'identifier': 'premium_yearly',
              'price': 99.99,
              'priceString': '\$99.99/year',
            },
          },
        ],
      };
    } catch (e) {
      print('Error getting offerings: $e');
      return null;
    }
  }

  /// Purchase subscription
  static Future<bool> purchaseSubscription(Map<String, dynamic> package) async {
    try {
      if (kIsWeb) return await _redirectToStore();
      
      // Simulate purchase and update Supabase
      await _syncSubscriptionToSupabase(package);
      return true;
    } catch (e) {
      print('Error purchasing subscription: $e');
      return false;
    }
  }

  /// Restore purchases
  static Future<bool> restorePurchases() async {
    try {
      if (kIsWeb) return await _checkSupabaseSubscription();
      
      // Check subscription status from Supabase
      return await _checkSupabaseSubscription();
    } catch (e) {
      print('Error restoring purchases: $e');
      return false;
    }
  }

  /// Get subscription status details
  static Future<Map<String, dynamic>> getSubscriptionDetails() async {
    try {
      if (kIsWeb) return await _getSupabaseSubscriptionDetails();
      
      final user = supabase.auth.currentUser;
      if (user == null) return {'isActive': false};

      final response = await supabase
          .from('users')
          .select('*')
          .eq('id', user.id)
          .single();

      final subscriptionStatus = response['subscription_status'] ?? 'inactive';
      final expiryDate = response['subscription_expiry'];
      final willRenew = response['subscription_will_renew'] ?? false;
      final latestPurchaseDate = response['subscription_start_date'];
      final originalPurchaseDate = response['subscription_start_date'];

      return {
        'isActive': subscriptionStatus == 'active',
        'expirationDate': expiryDate,
        'willRenew': willRenew,
        'periodType': response['subscription_type'] ?? 'unknown',
        'latestPurchaseDate': latestPurchaseDate,
        'originalPurchaseDate': originalPurchaseDate,
      };
    } catch (e) {
      print('Error getting subscription details: $e');
      return {'isActive': false};
    }
  }

  /// Get remaining trial days
  static Future<int?> getRemainingTrialDays() async {
    try {
      if (kIsWeb) return await _getSupabaseTrialDays();
      
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final response = await supabase
          .from('users')
          .select('subscription_expiry')
          .eq('id', user.id)
          .single();

      final expiryDate = response['subscription_expiry'];
      if (expiryDate != null) {
        final now = DateTime.now();
        final expiration = DateTime.parse(expiryDate);
        final difference = expiration.difference(now).inDays;
        return difference > 0 ? difference : 0;
      }
      return null;
    } catch (e) {
      print('Error getting trial days: $e');
      return null;
    }
  }

  /// Check if user is subscribed (alias for isSubscriptionActive)
  static Future<bool> isSubscribed() async {
    return await isSubscriptionActive();
  }

  /// Get customer info (alias for getSubscriptionDetails)
  static Future<Map<String, dynamic>> getCustomerInfo() async {
    return await getSubscriptionDetails();
  }

  /// Get offerings (alias for getCurrentOffering)
  static Future<Map<String, dynamic>?> getOfferings() async {
    return await getCurrentOffering();
  }

  /// Purchase a package
  static Future<bool> purchasePackage(Map<String, dynamic> package) async {
    return await purchaseSubscription(package);
  }

  /// Cancel subscription
  static Future<bool> cancelSubscription() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase
          .from('users')
          .update({
            'subscription_status': 'cancelled',
            'subscription_will_renew': false,
            'last_updated': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      return true;
    } catch (e) {
      print('Error cancelling subscription: $e');
      return false;
    }
  }

  /// Sync RevenueCat data to Supabase for analytics
  static Future<void> _syncSubscriptionToSupabase(Map<String, dynamic> package) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: package['packageType'] == 'MONTHLY' ? 30 : 365));

      await supabase
          .from('users')
          .update({
            'subscription_status': 'active',
            'subscription_type': package['packageType'] ?? 'unknown',
            'subscription_start_date': now.toIso8601String(),
            'subscription_expiry': expiryDate.toIso8601String(),
            'subscription_will_renew': true,
            'subscription_platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
            'last_updated': now.toIso8601String(),
          })
          .eq('id', user.id);

      print('Subscription synced to Supabase');
    } catch (e) {
      print('Error syncing subscription: $e');
    }
  }

  /// Sync user to Supabase
  static Future<void> _syncUserToSupabase(String userId) async {
    try {
      await supabase
          .from('users')
          .upsert({
            'id': userId,
            'created_at': DateTime.now().toIso8601String(),
            'subscription_status': 'inactive',
          });
    } catch (e) {
      print('Error syncing user: $e');
    }
  }

  // Fallback methods for web platform
  static Future<bool> _checkSupabaseSubscription() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;
      
      final response = await supabase
          .from('users')
          .select('subscription_status, subscription_expiry')
          .eq('id', user.id)
          .single();

      final status = response['subscription_status'] ?? 'inactive';
      final expiry = response['subscription_expiry'];
      
      if (status == 'active' && expiry != null) {
        return DateTime.now().isBefore(DateTime.parse(expiry));
      }
      return false;
    } catch (e) {
      print('Error checking Supabase subscription: $e');
      return false;
    }
  }

  static Future<bool> _redirectToStore() async {
    // Implementation for web store redirect
    return false;
  }

  static Future<Map<String, dynamic>> _getSupabaseSubscriptionDetails() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return {'isActive': false};
      
      final response = await supabase
          .from('users')
          .select('*')
          .eq('id', user.id)
          .single();

      return {
        'isActive': response['subscription_status'] == 'active',
        'expirationDate': response['subscription_expiry'],
        'willRenew': response['subscription_will_renew'] ?? false,
        'periodType': response['subscription_type'] ?? 'unknown',
        'latestPurchaseDate': response['subscription_start_date'],
        'originalPurchaseDate': response['subscription_start_date'],
      };
    } catch (e) {
      print('Error getting Supabase subscription details: $e');
      return {'isActive': false};
    }
  }

  static Future<int?> _getSupabaseTrialDays() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;
      
      final response = await supabase
          .from('users')
          .select('subscription_expiry')
          .eq('id', user.id)
          .single();

      final expiryDate = response['subscription_expiry'];
      if (expiryDate != null) {
        final now = DateTime.now();
        final expiration = DateTime.parse(expiryDate);
        final difference = expiration.difference(now).inDays;
        return difference > 0 ? difference : 0;
      }
      return null;
    } catch (e) {
      print('Error getting Supabase trial days: $e');
      return null;
    }
  }
} 