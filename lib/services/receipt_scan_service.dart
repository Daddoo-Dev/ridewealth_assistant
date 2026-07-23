import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scankit/scankit.dart' as scankit;
import 'package:sentry_flutter/sentry_flutter.dart';

import 'receipt_image_preprocessor.dart';
import 'receipt_text_parser.dart';

/// Fields parsed from a scanned receipt, ready to prefill an expense entry.
/// The receipt image itself is never kept past this call.
class ReceiptScanResult {
  const ReceiptScanResult({this.description, this.amount, this.date});

  final String? description;
  final double? amount;
  final DateTime? date;

  bool get hasSuggestions =>
      description != null || amount != null || date != null;

  static const empty = ReceiptScanResult();
}

/// Scans a receipt (camera document scan or a gallery photo), runs on-device
/// OCR, and heuristically parses it into [ReceiptScanResult]. Ported from
/// PeekPersonalFinance's ReceiptScanService, trimmed down: no payment-method
/// matching, no PDF import, no server-backed learning loop.
class ReceiptScanService {
  ReceiptScanService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  bool get documentScannerSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<ReceiptScanResult> scanWithDocumentScanner() async {
    if (!await _ensureCameraPermission()) return ReceiptScanResult.empty;

    if (kIsWeb) return _pickAndScan(ImageSource.camera);
    if (Platform.isAndroid) return _scanWithMlKitDocumentScanner();
    if (Platform.isIOS) return _scanWithVisionKit();
    return _pickAndScan(ImageSource.camera);
  }

  Future<ReceiptScanResult> pickFromGallery() => _pickAndScan(ImageSource.gallery);

  Future<bool> _ensureCameraPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<ReceiptScanResult> _scanWithMlKitDocumentScanner() async {
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        pageLimit: 1,
        mode: ScannerMode.full,
        isGalleryImport: false,
      ),
    );
    try {
      final scanResult = await scanner.scanDocument();
      final paths = scanResult.images;
      if (paths == null || paths.isEmpty) return ReceiptScanResult.empty;

      final bytes = await File(paths.first).readAsBytes();
      return _recognizeAndParse(bytes);
    } on PlatformException catch (e) {
      if (e.message == 'Operation cancelled') return ReceiptScanResult.empty;
      rethrow;
    } finally {
      await scanner.close();
    }
  }

  Future<ReceiptScanResult> _scanWithVisionKit() async {
    final supported = await scankit.ScanKit.isDocumentScanSupported();
    if (!supported) return _pickAndScan(ImageSource.camera);

    final scanResult = await scankit.ScanKit.scanDocument(
      maxPages: 1,
      allowGalleryImport: false,
    );
    if (scanResult == null || scanResult.pages.isEmpty) {
      return ReceiptScanResult.empty;
    }

    final bytes = await File(scanResult.pages.first.imagePath).readAsBytes();
    return _recognizeAndParse(bytes);
  }

  Future<ReceiptScanResult> _pickAndScan(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2400,
    );
    if (file == null) return ReceiptScanResult.empty;

    final bytes = await file.readAsBytes();
    return _recognizeAndParse(bytes);
  }

  Future<ReceiptScanResult> _recognizeAndParse(Uint8List bytes) async {
    try {
      final text = await _recognizeText(bytes);
      if (text == null || text.trim().isEmpty) return ReceiptScanResult.empty;

      final parsed = ReceiptTextParser.parse(text);
      return ReceiptScanResult(
        description: parsed.description,
        amount: parsed.amount,
        date: parsed.date,
      );
    } catch (e, stack) {
      debugPrint('ReceiptScanService OCR error: $e');
      await Sentry.captureException(e, stackTrace: stack);
      return ReceiptScanResult.empty;
    }
  }

  Future<String?> _recognizeText(Uint8List bytes) async {
    final enhanced = ReceiptImagePreprocessor.enhance(bytes);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/rwa_receipt_scan.jpg');
    await file.writeAsBytes(enhanced);

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final image = InputImage.fromFilePath(file.path);
      final result = await recognizer.processImage(image);
      return result.text.trim().isEmpty ? null : result.text;
    } finally {
      await recognizer.close();
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
