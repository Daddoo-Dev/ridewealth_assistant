// lib/services/apple/apple_payment_delegate.dart
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

class ApplePaymentDelegate implements SKPaymentQueueDelegateWrapper {
  const ApplePaymentDelegate();

  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction,
      SKStorefrontWrapper storefront,
      ) => true;

  @override
  bool shouldShowPriceConsent() => false;
}