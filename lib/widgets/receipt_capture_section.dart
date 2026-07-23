import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../services/receipt_scan_service.dart';
import '../theme/app_themes.dart';

/// "Scan Receipt" entry point for the Add Expense form. Offers a document
/// scan (camera) or a gallery photo, runs on-device OCR, and hands the parsed
/// fields back via [onScanned] for the caller to prefill its own form with —
/// the user still reviews and saves through the normal expense form.
class ReceiptCaptureSection extends StatefulWidget {
  const ReceiptCaptureSection({super.key, required this.onScanned});

  final ValueChanged<ReceiptScanResult> onScanned;

  @override
  State<ReceiptCaptureSection> createState() => _ReceiptCaptureSectionState();
}

class _ReceiptCaptureSectionState extends State<ReceiptCaptureSection> {
  final _service = ReceiptScanService();
  bool _scanning = false;

  Future<void> _showOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.document_scanner, color: AppThemes.primaryColor),
              title: Text('Scan receipt'),
              onTap: () {
                Navigator.pop(sheetContext);
                _runScan(_service.scanWithDocumentScanner);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppThemes.primaryColor),
              title: Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _runScan(_service.pickFromGallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runScan(Future<ReceiptScanResult> Function() action) async {
    setState(() => _scanning = true);
    try {
      final result = await action();
      if (!mounted) return;
      if (result.hasSuggestions) {
        widget.onScanned(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Couldn't read that receipt. You can still enter it manually.",
            ),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('ReceiptCaptureSection scan error: $e');
      Sentry.captureException(e, stackTrace: stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan receipt. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
        onPressed: _scanning ? null : _showOptions,
        icon: _scanning
            ? SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.receipt_long, color: AppThemes.primaryColor),
        label: Text(_scanning ? 'Scanning...' : 'Scan Receipt'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
