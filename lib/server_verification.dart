
class ServerVerification {
  // During testing, we'll bypass actual server verification
  static Future<bool> verifyPurchase(
      String productId, String purchaseToken) async {
    // Log the verification attempt for debugging
    print('Test verification for product: $productId');
    print('With token: $purchaseToken');

    // Return true for testing purposes
    return true;
  }
}