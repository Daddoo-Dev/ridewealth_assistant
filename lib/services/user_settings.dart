import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../localities.dart';
import '../locale_defaults.dart';
import '../mileage_rates.dart';
import '../money.dart';

class UserSettings {
  const UserSettings({
    required this.primaryRate,
    required this.secondaryRate,
    required this.distanceRate,
    required this.currencySymbol,
    required this.currencyName,
    required this.symbolAfter,
    required this.distanceUnit,
    required this.countryCode,
    required this.applyDistanceToSecondary,
  });

  final double primaryRate;
  final double secondaryRate;
  final double distanceRate;
  final String currencySymbol;
  final String currencyName;
  final bool symbolAfter;
  final String distanceUnit;
  final String? countryCode;
  final bool applyDistanceToSecondary;

  static const countryKey = 'countryCode';
  static const distanceOnSecondaryKey = 'applyDistanceToSecondary';

  static Future<bool> hasCountry() async {
    return (await storedCountryCode()) != null;
  }

  static Future<String?> storedCountryCode() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        final code = data?['countryCode'] as String?;
        if (Localities.byCode(code) != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(countryKey, code!);
          return code;
        }
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(countryKey);
    if (Localities.byCode(stored) != null) return stored;
    return null;
  }

  static Future<void> saveCountry(String code) async {
    final locality = Localities.byCode(code);
    if (locality == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(countryKey, code);
    _applyLocality(locality);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('users').upsert({
        'id': user.id,
        'countryCode': code,
      });
    } catch (_) {}
  }

  static void _applyLocality(Locality locality) {
    Money.symbol = locality.symbol;
    Money.symbolAfter = locality.symbolAfter;
  }

  static Future<UserSettings> load() async {
    final code = await storedCountryCode();
    final locality = Localities.byCode(code);
    if (locality != null) _applyLocality(locality);
    final prefs = await SharedPreferences.getInstance();
    final applyDistance = prefs.getBool(distanceOnSecondaryKey) ?? true;
    var primary = 0.15;
    var secondary = 0.05;
    double? storedDistance;

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (data != null) {
          primary = (data['federalRate'] as num?)?.toDouble() ?? primary;
          secondary = (data['stateRate'] as num?)?.toDouble() ?? secondary;
          storedDistance = (data['customMileageRate'] as num?)?.toDouble();
        }
      } catch (_) {}
    }

    final distance = LocaleDefaults.distanceRate(
      stored: storedDistance,
      unitedStates: locality?.countryCode == 'US',
      usDefault: currentUsDistanceRate(),
    );

    return UserSettings(
      primaryRate: primary,
      secondaryRate: secondary,
      distanceRate: distance,
      currencySymbol: locality?.symbol ?? Money.symbol,
      currencyName: locality?.currencyName ?? '',
      symbolAfter: locality?.symbolAfter ?? false,
      distanceUnit: locality?.distanceUnit ?? 'km',
      countryCode: locality?.countryCode,
      applyDistanceToSecondary: applyDistance,
    );
  }

  static Future<void> saveApplyDistanceToSecondary(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(distanceOnSecondaryKey, value);
  }

  static Future<void> saveRates({
    required double primaryRate,
    required double secondaryRate,
    required double distanceRate,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client.from('users').upsert({
      'id': user.id,
      'federalRate': primaryRate,
      'stateRate': secondaryRate,
      'customMileageRate': distanceRate,
    });
  }
}

double currentUsDistanceRate([DateTime? date]) {
  final when = date ?? DateTime.now();
  for (final rate in mileageRates.reversed) {
    if (!when.isBefore(rate.startDate)) return rate.rate;
  }
  return mileageRates.last.rate;
}
