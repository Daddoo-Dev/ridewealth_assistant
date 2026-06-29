import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform, kDebugMode;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
        debugPrint('RevenueCat debug mode enabled');
      }

      // Initialize RevenueCat with appropriate API key
      final apiKey = defaultTargetPlatform == TargetPlatform.iOS
          ? _iosApiKey
          : _androidApiKey;
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      // Configure RevenueCat
      await Purchases.configure(PurchasesConfiguration(apiKey));

      debugPrint('RevenueCat initialization completed');

      // If we have an initial user ID, set it immediately after configuration
      if (initialUserId != null) {
        debugPrint('Setting initial RevenueCat user: $initialUserId');
        await setRevenueCatUser(initialUserId);
      }
    } catch (e, stack) {
      debugPrint('Error initializing RevenueCat: $e');
      await Sentry.captureException(e, stackTrace: stack);
    }
  }

  /// Set RevenueCat user ID (no-op on web; subscription checked via Edge Function)
  static Future<void> setRevenueCatUser(String userId) async {
    if (kIsWeb) return;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final currentUserId = customerInfo.originalAppUserId;

      if (currentUserId != userId) {
        await Purchases.logIn(userId);
      }
    } catch (e) {
      debugPrint('Error setting RevenueCat user: $e');
    }
  }

  /// Get current RevenueCat user ID
  static Future<String?> getCurrentRevenueCatUserId() async {
    try {
      if (kIsWeb) return null;

      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.originalAppUserId;
    } catch (e) {
      debugPrint('Error getting RevenueCat user ID: $e');
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
      debugPrint('Error checking subscription: $e');
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
      debugPrint('Error checking subscription (web): $e');
      return false;
    }
  }

  /// Get available offerings (subscription packages)
  static Future<Map<String, dynamic>?> getCurrentOffering() async {
    try {
      if (kIsWeb) return null;

      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        debugPrint('No current offering available');
        return null;
      }

      final currentOffering = offerings.current!;
      final availablePackages =
          currentOffering.availablePackages.map((package) {
        final product = package.storeProduct;
        final intro = product.introductoryPrice;
        return {
          'identifier': package.identifier,
          'packageType': package.packageType.toString(),
          'title': product.title,
          'description': product.description,
          'product': {
            'identifier': product.identifier,
            'price': product.price,
            'priceString': product.priceString,
          },
          'introPriceString': intro?.priceString,
          'hasFreeTrial': intro != null && intro.price == 0,
        };
      }).toList();

      return {
        'identifier': currentOffering.identifier,
        'availablePackages': availablePackages,
      };
    } catch (e) {
      debugPrint('Error getting offerings: $e');
      return null;
    }
  }

  /// Purchase subscription via native App Store / Play Store billing.
  static Future<bool> purchaseSubscription(Map<String, dynamic> package) async {
    try {
      if (kIsWeb) return false;

      final packageId = package['identifier'] as String?;
      if (packageId == null || packageId.isEmpty) {
        throw Exception('Package identifier is required');
      }

      return await purchasePackageById(packageId);
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      rethrow;
    }
  }

  /// Purchase a RevenueCat package by identifier (native store checkout).
  static Future<bool> purchasePackageById(String packageId) async {
    if (kIsWeb) return false;

    final offerings = await Purchases.getOfferings();
    if (offerings.current == null) {
      throw Exception('No offerings available');
    }

    Package? packageToPurchase;
    for (final p in offerings.current!.availablePackages) {
      if (p.identifier == packageId) {
        packageToPurchase = p;
        break;
      }
    }

    if (packageToPurchase == null) {
      throw Exception('Package not found: $packageId');
    }

    final result = await Purchases.purchasePackage(packageToPurchase);
    return result.customerInfo.entitlements.active.isNotEmpty;
  }

  /// Restore purchases
  static Future<bool> restorePurchases() async {
    try {
      if (kIsWeb) return false;

      final customerInfo = await Purchases.restorePurchases();
      final isActive = customerInfo.entitlements.active.isNotEmpty;

      return isActive;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
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
      debugPrint('Error getting subscription details: $e');
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
      debugPrint('Error getting trial days: $e');
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
      debugPrint('Error getting trial status: $e');
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

  /// Purchase a package (map or package identifier string).
  static Future<bool> purchasePackage(dynamic package) async {
    if (package is String) {
      return purchasePackageById(package);
    }
    if (package is Map<String, dynamic>) {
      return purchaseSubscription(package);
    }
    throw Exception('Invalid package argument');
  }

  /// Cancel subscription
  static Future<bool> cancelSubscription() async {
    // RevenueCat doesn't provide direct cancellation - users must cancel through app store
    return true;
  }

}
