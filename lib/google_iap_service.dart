// lib/services/google/google_iap_service.dart
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class GoogleIAPService {
  static const String _annualSubId = 'com.ridewealthassistant.subscribe.annual';

  final InAppPurchase _iapInstance = InAppPurchase.instance;
  final supabase = Supabase.instance.client;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> initialize() async {
    if (!await _iapInstance.isAvailable()) {
      throw Exception('In-app purchases not available');
    }

    if (_iapInstance is InAppPurchaseAndroidPlatform) {
      final androidAddition = _iapInstance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      await androidAddition.queryPastPurchases();
    }

    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _iapInstance.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => throw Exception('IAP Stream error: $error'),
    );
  }

  Future<List<ProductDetails>> loadProducts() async {
    try {
      final ProductDetailsResponse response =
          await _iapInstance.queryProductDetails({_annualSubId});

      if (response.error != null) {
        print('Google product query error: ${response.error}');
        throw Exception('Error loading products: ${response.error}');
      }

      if (response.productDetails.isEmpty) {
        throw Exception('Product $_annualSubId not found');
      }

      return response.productDetails;
    } catch (e) {
      print('Error loading products: $e');
      rethrow;
    }
  }

  void Function()? _onPurchaseComplete;

  Future<void> purchaseProduct(
    ProductDetails product, {
    void Function()? onPurchaseComplete,
  }) async {
    _onPurchaseComplete = onPurchaseComplete;

    final user = supabase.auth.currentUser;
    final purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: user?.id,
    );

    try {
      final success =
          await _iapInstance.buyNonConsumable(purchaseParam: purchaseParam);
      if (!success) {
        throw Exception('Purchase flow failed to start');
      }
    } catch (e) {
      print('Error purchasing product: $e');
      _onPurchaseComplete = null;
      rethrow;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetails) {
    for (final purchase in purchaseDetails) {
      if (purchase.productID != _annualSubId) continue;
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          await _updateSubscriptionStatus(user.id, 'pending');
          return;

        case PurchaseStatus.error:
          await _updateSubscriptionStatus(user.id, 'error');
          print('Purchase error: ${purchase.error}');
          return;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _updateSubscriptionStatus(user.id, 'active');

          if (purchase.pendingCompletePurchase) {
            await _iapInstance.completePurchase(purchase);
          }
          _onPurchaseComplete?.call();
          _onPurchaseComplete = null;
          return;

        case PurchaseStatus.canceled:
          await _updateSubscriptionStatus(user.id, 'canceled');
          return;
      }
    } catch (e) {
      print('Error handling purchase: $e');
      await _updateSubscriptionStatus(user.id, 'error');
    }
  }

  Future<void> _updateSubscriptionStatus(
    String userId,
    String status,
  ) async {
    try {
      await supabase.from('users').upsert({
        'id': userId,
        'subscription_status': status,
        'subscription_platform': 'google',
        'subscription_id': _annualSubId,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating subscription status: $e');
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iapInstance.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
      rethrow;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
