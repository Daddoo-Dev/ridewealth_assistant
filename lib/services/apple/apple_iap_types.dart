// lib/services/apple/apple_iap_types.dart
class VerificationResult {
  final bool isValid;
  final String? error;
  final DateTime? expiryDate;

  const VerificationResult({
    required this.isValid,
    this.error,
    this.expiryDate,
  });
}