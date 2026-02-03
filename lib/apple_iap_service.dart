// lib/services/apple/apple_iap_service.dart
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import './services/apple/apple_payment_delegate.dart';
import './services/apple/receipt_validator.dart';

class AppleIAPService {
  static const String _productId = '1000001';

  final InAppPurchase _iap = InAppPurchase.instance;
  final supabase = Supabase.instance.client;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> initialize() async {
    if (!await _iap.isAvailable()) {
      throw Exception('In-app purchases not available');
    }

    final Stream<List<PurchaseDetails>> purchaseUpdates = _iap.purchaseStream;
    _subscription = purchaseUpdates.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        print('Purchase stream error: $error');
      },
    );

    if (_iap is InAppPurchaseStoreKitPlatform) {
      final iosPlatform =
          _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatform.setDelegate(ApplePaymentDelegate());
    }
  }

  Future<List<ProductDetails>> loadProducts() async {
    try {
      final response = await _iap.queryProductDetails({_productId});

      if (response.error != null) {
        throw response.error!;
      }

      if (response.productDetails.isEmpty) {
        throw Exception('No products found');
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
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!success) {
        throw Exception('Purchase flow failed to start');
      }
    } catch (e) {
      print('Error purchasing product: $e');
      _onPurchaseComplete = null;
      rethrow;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID != _productId) continue;
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
          if (purchase.verificationData.serverVerificationData.isEmpty) {
            await _updateSubscriptionStatus(user.id, 'error');
            return;
          }

          final result = await ReceiptValidator.verifyReceipt(
            purchase.verificationData.serverVerificationData,
          );

          if (result.isValid) {
            await _updateSubscriptionStatus(
              user.id,
              'active',
              result.expiryDate,
            );
          } else {
            await _updateSubscriptionStatus(user.id, 'invalid');
          }

          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
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
    String status, [
    DateTime? expiryDate,
  ]) async {
    try {
      await supabase.from('users').upsert({
        'id': userId,
        'subscription_status': status,
        'subscription_platform': 'apple',
        'subscription_id': _productId,
        if (expiryDate != null)
          'subscription_expiry': expiryDate.toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating subscription status: $e');
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
      rethrow;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
