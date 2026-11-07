class Money {
  static String symbol = r'$';
  static bool symbolAfter = false;

  static String format(num amount, [String? overrideSymbol, bool? after]) {
    final chosen = overrideSymbol ?? symbol;
    final placeAfter = after ?? (overrideSymbol == null && symbolAfter);
    final text = amount.toStringAsFixed(2);
    if (placeAfter) return '$text $chosen';
    final usesLetters = RegExp(r'[A-Za-z]').hasMatch(chosen);
    if (usesLetters) return '$chosen $text';
    return '$chosen$text';
  }
}
