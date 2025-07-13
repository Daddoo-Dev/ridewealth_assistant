import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, kDebugMode;
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatManager {
  // RevenueCat API Keys
  static const String _iosApiKey = 'appl_LGiUYfDhJkeeChtCBEyowyUORDA';
  static const String _androidApiKey = 'goog_nCTparCRddssvqMQrcRlaCjrEyR';
  static final supabase = Supabase.instance.client;

  /// Initialize RevenueCat
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        print('RevenueCat not available on web platform');
        return;
      }
      
      if (kDebugMode) {
        print('RevenueCat debug mode enabled');
      }

      // Initialize RevenueCat with appropriate API key
      final apiKey = defaultTargetPlatform == TargetPlatform.iOS ? _iosApiKey : _androidApiKey;
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      
      print('RevenueCat initialization completed');
    } catch (e) {
      print('Error initializing RevenueCat: $e');
    }
  }

  /// Set RevenueCat user ID
  static Future<void> setRevenueCatUser(String userId) async {
    try {
      await Purchases.logIn(userId);
      print('RevenueCat user set: $userId');
    } catch (e) {
      print('Error setting RevenueCat user: $e');
    }
  }

  /// Check if user has active subscription
  static Future<bool> isSubscriptionActive() async {
    try {
      if (kIsWeb) return false;
      
      // Check RevenueCat subscription status
      final customerInfo = await Purchases.getCustomerInfo();
      final isActive = customerInfo.entitlements.active.isNotEmpty;
      
      return isActive;
    } catch (e) {
      print('Error checking subscription: $e');
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
      final availablePackages = currentOffering.availablePackages.map((package) {
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
      
      final customerInfo = await Purchases.purchasePackage(packageToPurchase);
      final isActive = customerInfo.entitlements.active.isNotEmpty;
      
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
      if (kIsWeb) return {'isActive': false};
      
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
} 