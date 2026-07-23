/// Heuristic extraction from OCR text on a receipt.
///
/// Ported from PeekPersonalFinance's ReceiptTextParser, with the card-number
/// detection removed (this app has no payment-method concept to match against).
class ReceiptParsedFields {
  const ReceiptParsedFields({
    this.description,
    this.amount,
    this.date,
  });

  final String? description;
  final double? amount;
  final DateTime? date;

  static const empty = ReceiptParsedFields();
}

abstract final class ReceiptTextParser {
  static ReceiptParsedFields parse(String raw) {
    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return ReceiptParsedFields.empty;

    final description = _guessDescription(lines);
    return ReceiptParsedFields(
      description: isPlausibleMerchant(description) ? description : null,
      amount: _guessAmount(lines, raw),
      date: _guessDate(raw),
    );
  }

  /// Skip obvious OCR garbage for the description field.
  static bool isPlausibleMerchant(String? line) {
    if (line == null) return false;
    final text = line.trim();
    if (text.length < 2 || text.length > 80) return false;

    final letters = RegExp(r'[a-zA-Z]').allMatches(text).length;
    if (letters < 3 || letters < text.length * 0.35) return false;

    final alpha = text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (alpha.length >= 4 && !RegExp(r'[aeiouAEIOU]').hasMatch(alpha)) {
      return false;
    }

    if (RegExp(r'(.)\1{3,}').hasMatch(text)) return false;

    return true;
  }

  static String? _guessDescription(List<String> lines) {
    String? fallback;

    for (final line in lines.take(12)) {
      if (_looksLikeNoise(line)) continue;
      if (_looksLikeAddress(line)) continue;
      if (_looksLikePaymentOrPumpLine(line)) continue;
      if (RegExp(r'^\d').hasMatch(line) && !RegExp(r'[a-zA-Z]{3,}').hasMatch(line)) {
        continue;
      }
      if (!_hasEnoughLetters(line)) continue;

      final candidate = line.length > 80 ? '${line.substring(0, 80)}…' : line;
      if (_looksLikeMerchantName(line)) return candidate;
      fallback ??= candidate;
    }

    return fallback;
  }

  static bool _hasEnoughLetters(String line) {
    final letters = RegExp(r'[a-zA-Z]').allMatches(line).length;
    return letters >= 3;
  }

  static bool _looksLikeMerchantName(String line) {
    if (line.length < 2 || line.length > 48) return false;
    if (RegExp(r'\d{3,}').hasMatch(line)) return false;
    final letters = RegExp(r'[a-zA-Z]').allMatches(line).length;
    return letters >= line.length * 0.5;
  }

  static bool _looksLikeAddress(String line) {
    final lower = line.toLowerCase();
    return RegExp(
      r'\b(road|rd|street|st|ave|avenue|blvd|drive|dr|suite|ste|co\s+\d{5})\b',
      caseSensitive: false,
    ).hasMatch(lower);
  }

  static bool _looksLikePaymentOrPumpLine(String line) {
    final lower = line.toLowerCase();
    const markers = [
      'visa',
      'mastercard',
      'amex',
      'debit',
      'credit',
      'approved',
      'contactless',
      'auth no',
      'rrn',
      'terminal',
      'entry mode',
      'aid:',
      'seq#',
      'inv#',
      'pump',
      'unleaded',
      'price/g',
      'vol:',
      'store no',
      'trans:',
      'saved ',
      'per gallon',
      'please come',
    ];
    for (final marker in markers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }

  static bool _looksLikeNoise(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('thank you')) return true;
    if (RegExp(r'^(tel|phone|www\.|http)', caseSensitive: false).hasMatch(lower)) {
      return true;
    }
    return false;
  }

  static double? _guessAmount(List<String> lines, String raw) {
    final totalPattern = RegExp(
      r'(?:^|\b)(?:total|order\s+total|amount\s+due|balance\s+due|grand\s+total|amt\s+due)\b'
      r'[^\d\-]*(-?\$?\s*\d[\d,]*\.\d{2})',
      caseSensitive: false,
    );
    final moneyPattern = RegExp(r'-?\$?\s*(\d[\d,]*\.\d{2})');

    for (final line in lines) {
      if (RegExp(r'\bsubtotal\b', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      final totalMatch = totalPattern.firstMatch(line);
      if (totalMatch != null) {
        final v = _parseMoney(totalMatch.group(1)!);
        if (v != null && !_looksLikePricePerGallon(line, v)) {
          return v.abs();
        }
      }
    }

    final rawTotal = totalPattern.firstMatch(raw.replaceAll('\n', ' '));
    if (rawTotal != null) {
      final v = _parseMoney(rawTotal.group(1)!);
      if (v != null) return v.abs();
    }

    final candidates = <double>[];
    for (final line in lines) {
      if (RegExp(r'\bsubtotal\b', caseSensitive: false).hasMatch(line)) continue;
      if (_looksLikePaymentOrPumpLine(line)) continue;
      if (RegExp(r'\bprice\s*/?\s*g', caseSensitive: false).hasMatch(line)) continue;
      if (RegExp(r'\bvol\b', caseSensitive: false).hasMatch(line)) continue;

      for (final m in moneyPattern.allMatches(line)) {
        final v = _parseMoney(m.group(1)!);
        if (v == null) continue;
        if (_looksLikePricePerGallon(line, v)) continue;
        if (v > 0 && v < 1) continue;
        candidates.add(v);
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort();
    final largest = candidates.last;
    return largest.abs();
  }

  static bool _looksLikePricePerGallon(String line, double amount) {
    if (RegExp(r'\bprice\s*/?\s*g', caseSensitive: false).hasMatch(line)) {
      return true;
    }
    if (amount >= 2 && amount <= 9 && RegExp(r'\.\d{3}\b').hasMatch(line)) {
      return true;
    }
    return false;
  }

  static double? _parseMoney(String token) {
    final cleaned = token.replaceAll(RegExp(r'[^\d.\-]'), '');
    return double.tryParse(cleaned);
  }

  static DateTime? _guessDate(String raw) {
    final monthName = RegExp(
      r'\b(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2}),?\s+(\d{4})\b',
      caseSensitive: false,
    );
    final monthMatch = monthName.firstMatch(raw);
    if (monthMatch != null) {
      final month = _monthNumber(monthMatch.group(1)!);
      if (month != null) {
        final day = int.parse(monthMatch.group(2)!);
        final year = int.parse(monthMatch.group(3)!);
        return DateTime(year, month, day);
      }
    }

    final patterns = [
      RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b'),
      RegExp(r'\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})\b'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(raw);
      if (match == null) continue;
      try {
        if (match.groupCount >= 3 && (match.group(1)?.length ?? 0) == 4) {
          final y = int.parse(match.group(1)!);
          final m = int.parse(match.group(2)!);
          final d = int.parse(match.group(3)!);
          return DateTime(y, m, d);
        }
        var a = int.parse(match.group(1)!);
        var b = int.parse(match.group(2)!);
        var y = int.parse(match.group(3)!);
        if (y < 100) y += 2000;
        var month = a;
        var day = b;
        if (a > 12 && b <= 12) {
          day = a;
          month = b;
        }
        return DateTime(y, month, day);
      } on Object {
        continue;
      }
    }
    return null;
  }

  static int? _monthNumber(String name) {
    const months = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    return months[name.toLowerCase()];
  }
}
