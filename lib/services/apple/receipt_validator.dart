// lib/services/apple/receipt_validator.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'apple_iap_types.dart';

class ReceiptValidator {
  static const String _productId = '1000001';
  static const String _sharedSecret = 'da63044c37f2480ab79a9a7febcf8ce4';

  static Future<VerificationResult> verifyReceipt(String receiptData) async {
    try {
      final result = await _verifyWithEndpoint(
        'https://buy.itunes.apple.com/verifyReceipt',
        receiptData,
      );

      if (result['status'] == 21007) {
        return _parseResponse(await _verifyWithEndpoint(
          'https://sandbox.itunes.apple.com/verifyReceipt',
          receiptData,
        ));
      }

      return _parseResponse(result);
    } catch (e) {
      // Log error (could integrate with Supabase logging in the future)
      print('Receipt validation error: $e');
      return VerificationResult(isValid: false, error: e.toString());
    }
  }

  static Future<Map<String, dynamic>> _verifyWithEndpoint(
      String endpoint,
      String receiptData,
      ) async {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'receipt-data': receiptData,
        'password': _sharedSecret,
        'exclude-old-transactions': true,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Receipt verification failed: ${response.statusCode}');
    }

    return jsonDecode(response.body);
  }

  static VerificationResult _parseResponse(Map<String, dynamic> response) {
    final status = response['status'] as int;
    if (status != 0) {
      return VerificationResult(
        isValid: false,
        error: 'Invalid status: $status',
      );
    }

    final latestReceiptInfo = response['latest_receipt_info'] as List?;
    if (latestReceiptInfo == null || latestReceiptInfo.isEmpty) {
      return const VerificationResult(
        isValid: false,
        error: 'No receipt info found',
      );
    }

    final latest = latestReceiptInfo.last as Map<String, dynamic>;

    if (latest['product_id'] != _productId) {
      return const VerificationResult(
        isValid: false,
        error: 'Product ID mismatch',
      );
    }

    final expiresDateMs = int.parse(latest['expires_date_ms'] as String);
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(expiresDateMs);

    return VerificationResult(
      isValid: expirationDate.isAfter(DateTime.now()),
      expiryDate: expirationDate,
    );
  }
}