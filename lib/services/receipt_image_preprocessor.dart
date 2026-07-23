import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Contrast and light cleanup before ML Kit OCR on receipt photos.
abstract final class ReceiptImagePreprocessor {
  static Uint8List enhance(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    var result = img.grayscale(decoded);
    result = img.adjustColor(result, contrast: 1.3, brightness: 1.04);
    result = img.gaussianBlur(result, radius: 1);
    return Uint8List.fromList(img.encodeJpg(result, quality: 92));
  }
}
