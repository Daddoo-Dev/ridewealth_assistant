import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, kDebugMode;
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatManager {
  // RevenueCat API Keys
  static const String _iosApiKey = 'appl_LGiUYfDhJkeeChtCBEyowyUORDA';
  static const String _androidApiKey = 'goog_nCTparCRddssvqMQrcRlaCjrEyR';
  static final supabase = Supabase.instance.client;

  /// Initialize RevenueCat
  static Future<void> initialize({String? initialUserId}) async {
    try {
      if (kIsWeb) {
        return; // Subscription checked via Edge Function on web
      }

      if (kDebugMode) {
        print('RevenueCat debug mode enabled');
      }

      // Initialize RevenueCat with appropriate API key
      final apiKey = defaultTargetPlatform == TargetPlatform.iOS
          ? _iosApiKey
          : _androidApiKey;
      await Purchases.setLogLevel(LogLevel.debug);

      // Configure RevenueCat
      await Purchases.configure(PurchasesConfiguration(apiKey));

      print('RevenueCat initialization completed');

      // If we have an initial user ID, set it immediately after configuration
      if (initialUserId != null) {
        print('Setting initial RevenueCat user: $initialUserId');
        await setRevenueCatUser(initialUserId);
      }
    } catch (e) {
      print('Error initializing RevenueCat: $e');
    }
  }

  /// Set RevenueCat user ID (no-op on web; subscription checked via Edge Function)
  static Future<void> setRevenueCatUser(String userId) async {
    if (kIsWeb) return;
    try {
      print('=== RevenueCat User Setup ===');

      // First check if there's already a logged-in user
      final customerInfo = await Purchases.getCustomerInfo();
      final currentUserId = customerInfo.originalAppUserId;

      print('Current RevenueCat user: $currentUserId');
      print('Attempting to set RevenueCat user: $userId');

      // Check if this is an anonymous user
      if (currentUserId.startsWith('\$RCAnonymousID:')) {
        print('Found anonymous user, attempting to create new user');

        // For anonymous users, we can't log out, so we need to use logIn directly
        // This will create a new user with the specified ID
        await Purchases.logIn(userId);
        print('Logged in to RevenueCat with user: $userId');

        // Verify the login worked
        final newCustomerInfo = await Purchases.getCustomerInfo();
        final newUserId = newCustomerInfo.originalAppUserId;
        print('New RevenueCat user after login: $newUserId');

        if (newUserId == userId) {
          print('✅ Successfully set RevenueCat user to: $userId');
        } else {
          print(
              '❌ Failed to set RevenueCat user. Expected: $userId, Got: $newUserId');
        }
      } else if (currentUserId != userId) {
        print('Different user logged in, switching to: $userId');
        await Purchases.logIn(userId);
        print('RevenueCat user switched to: $userId');
      } else {
        print('RevenueCat user already set to: $userId');
      }

      print('=== End RevenueCat User Setup ===');
    } catch (e) {
      print('Error setting RevenueCat user: $e');
    }
  }

  /// Get current RevenueCat user ID
  static Future<String?> getCurrentRevenueCatUserId() async {
    try {
      if (kIsWeb) return null;

      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.originalAppUserId;
    } catch (e) {
      print('Error getting RevenueCat user ID: $e');
      return null;
    }
  }

  /// Check if user has active subscription (web: via Edge Function + RevenueCat v2)
  static Future<bool> isSubscriptionActive() async {
    try {
      if (kIsWeb) {
        return _checkSubscriptionStatusWeb();
      }
      final customerInfo = await Purchases.getCustomerInfo();
      final isActive = customerInfo.entitlements.active.isNotEmpty;
      return isActive;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  /// Web: call Supabase Edge Function which checks RevenueCat v2 active_entitlements
  static Future<bool> _checkSubscriptionStatusWeb() async {
    try {
      final res = await supabase.functions.invoke('check_subscription');
      if (res.status != 200) return false;
      final data = res.data as Map<String, dynamic>?;
      return data?['active'] == true;
    } catch (e) {
      print('Error checking subscription (web): $e');
      return false;
    }
  }

  /// Get available offerings (subscription packages)
  static Future<Map<String, dynamic>?> getCurrentOffering() async {
    try {
      if (kIsWeb) return null;

      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        print('No current offering available');
        return null;
      }

      final currentOffering = offerings.current!;
      final availablePackages =
          currentOffering.availablePackages.map((package) {
        return {
          'identifier': package.identifier,
          'packageType': package.packageType.toString(),
          'product': {
            'identifier': package.storeProduct.identifier,
            'price': package.storeProduct.price,
            'priceString': package.storeProduct.priceString,
          },
        };
      }).toList();

      return {
        'identifier': currentOffering.identifier,
        'availablePackages': availablePackages,
      };
    } catch (e) {
      print('Error getting offerings: $e');
      return null;
    }
  }

  /// Purchase subscription
  static Future<bool> purchaseSubscription(Map<String, dynamic> package) async {
    try {
      if (kIsWeb) return false;

      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        throw Exception('No offerings available');
      }

      final packageToPurchase = offerings.current!.availablePackages
          .firstWhere((p) => p.identifier == package['identifier']);

      final result = await Purchases.purchasePackage(packageToPurchase);
      final isActive = result.customerInfo.entitlements.active.isNotEmpty;

      return isActive;
    } catch (e) {
      print('Error purchasing subscription: $e');
      return false;
    }
  }

  /// Restore purchases
  static Future<bool> restorePurchases() async {
    try {
      if (kIsWeb) return false;

      final customerInfo = await Purchases.restorePurchases();
      final isActive = customerInfo.entitlements.active.isNotEmpty;

      return isActive;
    } catch (e) {
      print('Error restoring purchases: $e');
      return false;
    }
  }

  /// Get subscription status details
  static Future<Map<String, dynamic>> getSubscriptionDetails() async {
    try {
      if (kIsWeb) {
        final active = await _checkSubscriptionStatusWeb();
        return {'isActive': active, 'hasActiveSubscription': active};
      }
      final customerInfo = await Purchases.getCustomerInfo();
      final isActive = customerInfo.entitlements.active.isNotEmpty;
      return {
        'isActive': isActive,
        'hasActiveSubscription': isActive,
      };
    } catch (e) {
      print('Error getting subscription details: $e');
      return {'isActive': false};
    }
  }

  /// Get remaining trial days
  static Future<int?> getRemainingTrialDays() async {
    try {
      if (kIsWeb) return null;
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.active.values.firstOrNull;
      if (entitlement == null) return null;
      if (entitlement.periodType != PeriodType.trial) return null;

      final dynamic expiration = entitlement.expirationDate;
      DateTime? expirationDate;
      if (expiration is DateTime) {
        expirationDate = expiration;
      } else if (expiration is String) {
        expirationDate = DateTime.tryParse(expiration);
      }

      if (expirationDate == null) return null;
      final now = DateTime.now();
      final remaining = expirationDate.difference(now).inDays;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      print('Error getting trial days: $e');
      return null;
    }
  }

  /// Get trial status and details
  static Future<Map<String, dynamic>> getTrialStatus() async {
    try {
      if (kIsWeb) return {'isInTrial': false, 'daysRemaining': 0};

      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.active.values.firstOrNull;

      if (entitlement == null) {
        return {'isInTrial': false, 'daysRemaining': 0};
      }

      if (entitlement.periodType != PeriodType.trial) {
        return {'isInTrial': false, 'daysRemaining': 0};
      }

      final dynamic expiration = entitlement.expirationDate;
      DateTime? expirationDate;
      if (expiration is DateTime) {
        expirationDate = expiration;
      } else if (expiration is String) {
        expirationDate = DateTime.tryParse(expiration);
      }

      if (expirationDate == null) {
        return {'isInTrial': false, 'daysRemaining': 0};
      }

      final now = DateTime.now();
      final remaining = expirationDate.difference(now).inDays;

      return {
        'isInTrial': remaining > 0,
        'daysRemaining': remaining > 0 ? remaining : 0,
        'expirationDate': expirationDate.toIso8601String(),
      };
    } catch (e) {
      print('Error getting trial status: $e');
      return {'isInTrial': false, 'daysRemaining': 0};
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
    // RevenueCat doesn't provide direct cancellation - users must cancel through app store
    return true;
  }

  /// Force reset RevenueCat user ID (use with caution)
  static Future<void> forceResetUser(String userId) async {
    try {
      print('=== Force Reset RevenueCat User ===');

      // First log out to clear any existing user
      await Purchases.logOut();
      print('Logged out of RevenueCat');

      // Wait a moment for the logout to complete
      await Future.delayed(Duration(milliseconds: 500));

      // Now log in with the new user ID
      await Purchases.logIn(userId);
      print('Logged in to RevenueCat with user: $userId');

      // Verify the login worked
      final customerInfo = await Purchases.getCustomerInfo();
      final newUserId = customerInfo.originalAppUserId;
      print('New RevenueCat user after force reset: $newUserId');

      if (newUserId == userId) {
        print('✅ Successfully force reset RevenueCat user to: $userId');
      } else {
        print(
            '❌ Failed to force reset RevenueCat user. Expected: $userId, Got: $newUserId');
      }

      print('=== End Force Reset RevenueCat User ===');
    } catch (e) {
      print('Error force resetting RevenueCat user: $e');
    }
  }

  /// Completely reset RevenueCat (nuclear option)
  static Future<void> nuclearReset() async {
    try {
      print('=== NUCLEAR RESET REVENUECAT ===');

      // Log out completely
      await Purchases.logOut();
      print('Logged out of RevenueCat');

      // Wait for logout to complete
      await Future.delayed(Duration(seconds: 1));

      // Clear any cached data by getting fresh customer info
      await Purchases.getCustomerInfo();

      print('=== END NUCLEAR RESET ===');
    } catch (e) {
      print('Error during nuclear reset: $e');
    }
  }

  /// Completely clear all RevenueCat data and start fresh
  static Future<void> clearAllData() async {
    try {
      print('=== CLEARING ALL REVENUECAT DATA ===');

      // Log out completely
      await Purchases.logOut();
      print('Logged out of RevenueCat');

      // Wait for logout to complete
      await Future.delayed(Duration(seconds: 1));

      // Force a fresh customer info request to clear cache
      await Purchases.getCustomerInfo();

      print('=== END CLEARING ALL REVENUECAT DATA ===');
    } catch (e) {
      print('Error clearing RevenueCat data: $e');
    }
  }
}
