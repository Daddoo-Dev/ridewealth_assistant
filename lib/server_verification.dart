import 'package:http/http.dart' as http;
import 'dart:convert';

class ServerVerification {
  static const String _serverUrl =
      'https://your-server-url.com/verify-purchase';

  static Future<bool> verifyPurchase(
      String productId, String purchaseToken) async {
    try {
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'productId': productId,
          'purchaseToken': purchaseToken,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['isValid'] == true;
      } else {
        print('Server verification failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error during server verification: $e');
      return false;
    }
  }
}
