import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'server_verification.dart';

class InAppPurchaseManager {
  static const String _kSubscriptionId = 'your_subscription_id_here';
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      print('In-app purchases not available');
      return;
    }

    await _getProducts();
    await _getPastPurchases();

    _subscription = _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) => print('Error in purchaseStream: $error'),
    );
  }

  Future<void> _getProducts() async {
    Set<String> kIds = <String>{_kSubscriptionId};
    ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(kIds);
    if (productDetailResponse.error != null) {
      print('Error querying product details: ${productDetailResponse.error}');
    }
    List<ProductDetails> products = productDetailResponse.productDetails;
    print('Products found: ${products.length}');
  }

  Future<void> _getPastPurchases() async {
    print('Restoring purchases');
    try {
      await _inAppPurchase.restorePurchases();
      print('Purchases restored successfully');
    } catch (error) {
      print('Error restoring purchases: $error');
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('Purchase pending');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          print('Error purchasing: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          print('Purchase completed');
          await _handlePurchase(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.restored) {
          print('Purchase restored');
          await _handlePurchase(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
          print('Purchase completed');
        }
      }
    });
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    // Verify purchase on the server
    bool isValid = await _verifyPurchase(purchase);
    if (isValid) {
      print('Valid purchase for product: ${purchase.productID}');
      // You'll call SubscriptionManager.startSubscription() here
    } else {
      print('Invalid purchase for product: ${purchase.productID}');
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    print('Verifying purchase for product: ${purchase.productID}');
    return await ServerVerification.verifyPurchase(
        purchase.productID, purchase.verificationData.serverVerificationData);
  }

  Future<void> buySubscription() async {
    print('Initiating subscription purchase');
    Set<String> kIds = <String>{_kSubscriptionId};
    ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(kIds);
    if (response.notFoundIDs.isNotEmpty) {
      print('Product not found: ${response.notFoundIDs}');
      return;
    }
    ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    try {
      final bool purchaseResult =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      print('Purchase initiated: $purchaseResult');
    } catch (error) {
      print('Error initiating purchase: $error');
    }
  }

  void dispose() {
    print('Disposing InAppPurchaseManager');
    _subscription.cancel();
  }
}
