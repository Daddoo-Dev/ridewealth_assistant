import '../services/feature_flag_service.dart';

class SubscriptionService {
  Future<bool> hasActiveSubscription() async {
    // If subscriptions are disabled, always return true
    if (!FeatureFlags.subscriptionCheckEnabled) {
      return true;
    }
    
    // Add default return for existing code
    return false; // or whatever your existing logic returns
  }

  Future<void> checkSubscriptionStatus() async {
    // If subscriptions are disabled, skip the check
    if (!FeatureFlags.subscriptionCheckEnabled) {
      return;
    }
    
    // ... existing check code ...
  }
} 