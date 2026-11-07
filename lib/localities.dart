class Locality {
  const Locality({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.currencyName,
    required this.symbol,
    this.symbolAfter = false,
    this.usesMiles = false,
  });

  final String countryCode;
  final String countryName;
  final String currencyCode;
  final String currencyName;
  final String symbol;
  final bool symbolAfter;
  final bool usesMiles;

  String get distanceUnit => usesMiles ? 'miles' : 'km';

  String get distanceWord => usesMiles ? 'miles' : 'kilometers';
}

abstract final class Localities {
  static Locality? byCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final locality in all) {
      if (locality.countryCode == code) return locality;
    }
    return null;
  }

  static List<Locality> matching(String query) {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return all;
    return all.where((locality) {
      return locality.countryName.toLowerCase().contains(text) ||
          locality.currencyName.toLowerCase().contains(text) ||
          locality.countryCode.toLowerCase() == text;
    }).toList();
  }

  static const List<Locality> all = [
    Locality(countryCode: 'AR', countryName: 'Argentina', currencyCode: 'ARS', currencyName: 'Argentine peso', symbol: r'AR$'),
    Locality(countryCode: 'AU', countryName: 'Australia', currencyCode: 'AUD', currencyName: 'Australian dollar', symbol: r'A$'),
    Locality(countryCode: 'AT', countryName: 'Austria', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'BE', countryName: 'Belgium', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'BR', countryName: 'Brazil', currencyCode: 'BRL', currencyName: 'Brazilian real', symbol: r'R$'),
    Locality(countryCode: 'BG', countryName: 'Bulgaria', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'CA', countryName: 'Canada', currencyCode: 'CAD', currencyName: 'Canadian dollar', symbol: r'CA$'),
    Locality(countryCode: 'CL', countryName: 'Chile', currencyCode: 'CLP', currencyName: 'Chilean peso', symbol: r'CL$'),
    Locality(countryCode: 'CN', countryName: 'China', currencyCode: 'CNY', currencyName: 'Chinese yuan', symbol: '¥'),
    Locality(countryCode: 'CO', countryName: 'Colombia', currencyCode: 'COP', currencyName: 'Colombian peso', symbol: r'CO$'),
    Locality(countryCode: 'CR', countryName: 'Costa Rica', currencyCode: 'CRC', currencyName: 'Costa Rican colón', symbol: '₡'),
    Locality(countryCode: 'HR', countryName: 'Croatia', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'CY', countryName: 'Cyprus', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'CZ', countryName: 'Czechia', currencyCode: 'CZK', currencyName: 'Czech koruna', symbol: 'Kč', symbolAfter: true),
    Locality(countryCode: 'DK', countryName: 'Denmark', currencyCode: 'DKK', currencyName: 'Danish krone', symbol: 'kr', symbolAfter: true),
    Locality(countryCode: 'EE', countryName: 'Estonia', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'FI', countryName: 'Finland', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'FR', countryName: 'France', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'DE', countryName: 'Germany', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'GH', countryName: 'Ghana', currencyCode: 'GHS', currencyName: 'Ghanaian cedi', symbol: 'GH₵'),
    Locality(countryCode: 'GR', countryName: 'Greece', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'HK', countryName: 'Hong Kong', currencyCode: 'HKD', currencyName: 'Hong Kong dollar', symbol: r'HK$'),
    Locality(countryCode: 'HU', countryName: 'Hungary', currencyCode: 'HUF', currencyName: 'Hungarian forint', symbol: 'Ft', symbolAfter: true),
    Locality(countryCode: 'IS', countryName: 'Iceland', currencyCode: 'ISK', currencyName: 'Icelandic króna', symbol: 'kr', symbolAfter: true),
    Locality(countryCode: 'IN', countryName: 'India', currencyCode: 'INR', currencyName: 'Indian rupee', symbol: '₹'),
    Locality(countryCode: 'ID', countryName: 'Indonesia', currencyCode: 'IDR', currencyName: 'Indonesian rupiah', symbol: 'Rp'),
    Locality(countryCode: 'IE', countryName: 'Ireland', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'IL', countryName: 'Israel', currencyCode: 'ILS', currencyName: 'Israeli shekel', symbol: '₪'),
    Locality(countryCode: 'IT', countryName: 'Italy', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'JP', countryName: 'Japan', currencyCode: 'JPY', currencyName: 'Japanese yen', symbol: '¥'),
    Locality(countryCode: 'KE', countryName: 'Kenya', currencyCode: 'KES', currencyName: 'Kenyan shilling', symbol: 'KSh'),
    Locality(countryCode: 'LV', countryName: 'Latvia', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'LT', countryName: 'Lithuania', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'LU', countryName: 'Luxembourg', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'MY', countryName: 'Malaysia', currencyCode: 'MYR', currencyName: 'Malaysian ringgit', symbol: 'RM'),
    Locality(countryCode: 'MT', countryName: 'Malta', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'MX', countryName: 'Mexico', currencyCode: 'MXN', currencyName: 'Mexican peso', symbol: r'MX$'),
    Locality(countryCode: 'NL', countryName: 'Netherlands', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'NZ', countryName: 'New Zealand', currencyCode: 'NZD', currencyName: 'New Zealand dollar', symbol: r'NZ$'),
    Locality(countryCode: 'NG', countryName: 'Nigeria', currencyCode: 'NGN', currencyName: 'Nigerian naira', symbol: '₦'),
    Locality(countryCode: 'NO', countryName: 'Norway', currencyCode: 'NOK', currencyName: 'Norwegian krone', symbol: 'kr', symbolAfter: true),
    Locality(countryCode: 'PK', countryName: 'Pakistan', currencyCode: 'PKR', currencyName: 'Pakistani rupee', symbol: 'Rs'),
    Locality(countryCode: 'PE', countryName: 'Peru', currencyCode: 'PEN', currencyName: 'Peruvian sol', symbol: 'S/'),
    Locality(countryCode: 'PH', countryName: 'Philippines', currencyCode: 'PHP', currencyName: 'Philippine peso', symbol: '₱'),
    Locality(countryCode: 'PL', countryName: 'Poland', currencyCode: 'PLN', currencyName: 'Polish złoty', symbol: 'zł', symbolAfter: true),
    Locality(countryCode: 'PT', countryName: 'Portugal', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'RO', countryName: 'Romania', currencyCode: 'RON', currencyName: 'Romanian leu', symbol: 'lei', symbolAfter: true),
    Locality(countryCode: 'SA', countryName: 'Saudi Arabia', currencyCode: 'SAR', currencyName: 'Saudi riyal', symbol: 'SAR'),
    Locality(countryCode: 'SG', countryName: 'Singapore', currencyCode: 'SGD', currencyName: 'Singapore dollar', symbol: r'S$'),
    Locality(countryCode: 'SK', countryName: 'Slovakia', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'SI', countryName: 'Slovenia', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'ZA', countryName: 'South Africa', currencyCode: 'ZAR', currencyName: 'South African rand', symbol: 'R'),
    Locality(countryCode: 'KR', countryName: 'South Korea', currencyCode: 'KRW', currencyName: 'South Korean won', symbol: '₩'),
    Locality(countryCode: 'ES', countryName: 'Spain', currencyCode: 'EUR', currencyName: 'Euro', symbol: '€', symbolAfter: true),
    Locality(countryCode: 'SE', countryName: 'Sweden', currencyCode: 'SEK', currencyName: 'Swedish krona', symbol: 'kr', symbolAfter: true),
    Locality(countryCode: 'CH', countryName: 'Switzerland', currencyCode: 'CHF', currencyName: 'Swiss franc', symbol: 'CHF', symbolAfter: true),
    Locality(countryCode: 'TW', countryName: 'Taiwan', currencyCode: 'TWD', currencyName: 'New Taiwan dollar', symbol: r'NT$'),
    Locality(countryCode: 'TH', countryName: 'Thailand', currencyCode: 'THB', currencyName: 'Thai baht', symbol: '฿'),
    Locality(countryCode: 'TR', countryName: 'Turkey', currencyCode: 'TRY', currencyName: 'Turkish lira', symbol: '₺'),
    Locality(countryCode: 'AE', countryName: 'United Arab Emirates', currencyCode: 'AED', currencyName: 'UAE dirham', symbol: 'AED'),
    Locality(countryCode: 'GB', countryName: 'United Kingdom', currencyCode: 'GBP', currencyName: 'Pound sterling', symbol: '£', usesMiles: true),
    Locality(countryCode: 'US', countryName: 'United States', currencyCode: 'USD', currencyName: 'US dollar', symbol: r'$', usesMiles: true),
    Locality(countryCode: 'VN', countryName: 'Vietnam', currencyCode: 'VND', currencyName: 'Vietnamese dong', symbol: '₫', symbolAfter: true),
  ];
}
