import 'package:cloud_firestore/cloud_firestore.dart';
import 'in_app_purchase_manager.dart';

class SubscriptionManager {
  static const String userCollection = 'users';
  static final InAppPurchaseManager _iapManager = InAppPurchaseManager();

  static Future<void> initialize() async {
    await _iapManager.initStoreInfo();
  }

  static Future<bool> isSubscriptionActive(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection(userCollection)
        .doc(userId)
        .get();
    final userData = userDoc.data();

    if (userData != null) {
      final isSubscribed = userData['isSubscribed'] as bool? ?? false;
      final subscriptionEndDate = userData['subscriptionEndDate'] as Timestamp?;
      final currentDate = Timestamp.now();

      return isSubscribed &&
          subscriptionEndDate != null &&
          currentDate.compareTo(subscriptionEndDate) <= 0;
    }

    return false;
  }

  static Future<void> checkAndStartFreeTrial(String userId) async {
    final userDoc =
        FirebaseFirestore.instance.collection(userCollection).doc(userId);
    final snapshot = await userDoc.get();
    final userData = snapshot.data();

    if (userData == null || !userData.containsKey('freeTrialUsed')) {
      await startFreeTrial(userId);
    }
  }

  static Future<void> startFreeTrial(String userId) async {
    final userDoc =
        FirebaseFirestore.instance.collection(userCollection).doc(userId);
    final currentDate = Timestamp.now();
    final freeTrialEndDate =
        Timestamp.fromDate(currentDate.toDate().add(Duration(days: 30)));

    await userDoc.set({
      'subscriptionStartDate': currentDate,
      'subscriptionEndDate': freeTrialEndDate,
      'isSubscribed': true,
      'freeTrialUsed': true,
      'subscriptionType': 'freeTrial',
    }, SetOptions(merge: true));
  }

  static Future<void> startSubscription(String userId) async {
    final userDoc =
        FirebaseFirestore.instance.collection(userCollection).doc(userId);
    final currentDate = Timestamp.now();
    final subscriptionEndDate =
        Timestamp.fromDate(currentDate.toDate().add(Duration(days: 365)));

    await userDoc.set({
      'subscriptionStartDate': currentDate,
      'subscriptionEndDate': subscriptionEndDate,
      'isSubscribed': true,
      'subscriptionType': 'paid',
    }, SetOptions(merge: true));
  }

  static Future<void> cancelSubscription(String userId) async {
    final userDoc =
        FirebaseFirestore.instance.collection(userCollection).doc(userId);
    await userDoc.update({
      'isSubscribed': false,
      'subscriptionType': 'cancelled',
    });
  }

  static Future<void> renewSubscription(String userId) async {
    final userDoc =
        FirebaseFirestore.instance.collection(userCollection).doc(userId);
    final snapshot = await userDoc.get();
    final userData = snapshot.data();

    if (userData != null && userData.containsKey('subscriptionEndDate')) {
      final currentEndDate = userData['subscriptionEndDate'] as Timestamp;
      final newEndDate =
          Timestamp.fromDate(currentEndDate.toDate().add(Duration(days: 365)));

      await userDoc.update({
        'subscriptionEndDate': newEndDate,
        'isSubscribed': true,
        'subscriptionType': 'paid',
      });
    }
  }

  static Future<Map<String, dynamic>> getSubscriptionDetails(
      String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection(userCollection)
        .doc(userId)
        .get();
    final userData = userDoc.data();

    if (userData != null) {
      return {
        'subscriptionStartDate': userData['subscriptionStartDate'],
        'subscriptionEndDate': userData['subscriptionEndDate'],
        'isSubscribed': userData['isSubscribed'],
        'freeTrialUsed': userData['freeTrialUsed'],
        'subscriptionType': userData['subscriptionType'],
      };
    }

    return {};
  }

  static Future<void> checkAndRenewSubscription(String userId) async {
    final userDoc =
        FirebaseFirestore.instance.collection(userCollection).doc(userId);
    final snapshot = await userDoc.get();
    final userData = snapshot.data();

    if (userData != null && userData['isSubscribed'] == true) {
      final subscriptionEndDate = userData['subscriptionEndDate'] as Timestamp;
      final currentDate = Timestamp.now();

      if (currentDate.compareTo(subscriptionEndDate) > 0) {
        // Subscription has expired, attempt to renew
        try {
          await _iapManager.buySubscription();
          // The actual renewal will be handled in the purchase stream listener
        } catch (e) {
          print('Failed to renew subscription: $e');
          await cancelSubscription(userId);
        }
      }
    }
  }

  static Future<void> purchaseSubscription() async {
    await _iapManager.buySubscription();
  }

  static void dispose() {
    _iapManager.dispose();
  }
}
