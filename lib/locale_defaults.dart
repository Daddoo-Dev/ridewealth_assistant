import 'package:intl/intl.dart';

/// Device-locale defaults. A stored rate or symbol always wins.
class LocaleDefaults {
  static bool isUnitedStates(String? countryCode) => countryCode == 'US';

  static double distanceRate({
    required double? stored,
    required bool unitedStates,
    required double usDefault,
  }) {
    if (stored != null && stored > 0) return stored;
    if (unitedStates) return usDefault;
    return 0;
  }

  static String currencySymbolFor(String localeName) {
    final symbol = NumberFormat.simpleCurrency(locale: localeName).currencySymbol;
    if (symbol.trim().isEmpty) return r'$';
    return symbol;
  }
}
