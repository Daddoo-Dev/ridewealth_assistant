import 'package:flutter_test/flutter_test.dart';
import 'package:ridewealth_assistant/ledger_math.dart';
import 'package:ridewealth_assistant/localities.dart';
import 'package:ridewealth_assistant/locale_defaults.dart';
import 'package:ridewealth_assistant/mileage_rules.dart';
import 'package:ridewealth_assistant/money.dart';
import 'package:ridewealth_assistant/services/network_failure.dart';
import 'package:ridewealth_assistant/services/receipt_text_parser.dart';

void main() {
  test('quarter period follows calendar quarters', () {
    final first = QuarterPeriod.containing(DateTime(2026, 3, 15));
    expect(first.label, 'Q1 2026');
    expect(first.start, DateTime(2026, 1, 1));
    expect(first.end, DateTime(2026, 3, 31, 23, 59, 59));

    final second = QuarterPeriod.containing(DateTime(2026, 4, 1));
    expect(second.label, 'Q2 2026');
  });

  test('set-aside uses one distance rate for the whole period', () {
    final estimate = SetAsideEstimate.compute(
      income: 1000,
      expenses: 200,
      distance: 100,
      distanceRate: 0.70,
      primaryRate: 0.15,
      secondaryRate: 0.05,
      applyDistanceToSecondary: true,
    );

    expect(estimate.distanceDeduction, 70);
    expect(estimate.onIncome.primary, 150);
    expect(estimate.onIncome.secondary, 50);
    expect(estimate.afterExpenses.base, 800);
    expect(estimate.afterExpenses.primary, 120);
    expect(estimate.afterExpenses.secondary, 40);
    expect(estimate.afterDistance.base, 730);
    expect(estimate.afterDistance.primary, closeTo(109.5, 0.001));
    expect(estimate.afterDistance.secondary, closeTo(36.5, 0.001));
  });

  test('secondary tax can ignore the distance deduction', () {
    final estimate = SetAsideEstimate.compute(
      income: 1000,
      expenses: 200,
      distance: 100,
      distanceRate: 0.70,
      primaryRate: 0.15,
      secondaryRate: 0.05,
      applyDistanceToSecondary: false,
    );

    expect(estimate.afterDistance.primary, closeTo(109.5, 0.001));
    expect(estimate.afterDistance.secondary, 40);
  });

  test('export summary matches the same distance deduction', () {
    final rows = buildFinancialExportRows(
      income: [
        {'amount': 1000},
      ],
      expenses: [
        {'amount': 100, 'category': 'Fuel'},
        {
          'amount': 40,
          'category': 'Estimated Tax Payment',
          'description': 'state payment',
        },
        {
          'amount': 10,
          'category': 'Estimated Tax Payment',
          'description': 'primary payment',
        },
      ],
      mileage: [
        {'start_mileage': 1000, 'end_mileage': 1100},
      ],
      distanceRate: 0.70,
      expenseCategories: ['Fuel', 'Estimated Tax Payment'],
    );

    expect(rows, containsAll([
      ['Total Income', '1000.00'],
      ['Total Expenses', '150.00'],
      ['Total distance deduction', '70.00'],
      ['Net Income', '780.00'],
      ['Estimated payments (primary)', '10.00'],
      ['Estimated payments (secondary)', '40.00'],
    ]));

    final estimate = SetAsideEstimate.compute(
      income: 1000,
      expenses: 150,
      distance: 100,
      distanceRate: 0.70,
      primaryRate: 0.15,
      secondaryRate: 0.05,
      applyDistanceToSecondary: true,
    );
    expect(estimate.distanceDeduction, 70);
    expect(estimate.afterDistance.base, 780);
  });

  test('distance rate accepts a decimal comma and rejects values above 5', () {
    expect(parseDistanceRate('3,50'), 3.5);
    expect(parseDistanceRate('0.70'), 0.70);
    expect(parseDistanceRate(''), 0);
    expect(parseDistanceRate('5.01'), isNull);
    expect(parseDistanceRate('nope'), isNull);
  });

  test('a stored distance rate wins, and the US table is only the US default', () {
    expect(
      LocaleDefaults.distanceRate(stored: 3.5, unitedStates: false, usDefault: 0.73),
      3.5,
    );
    expect(
      LocaleDefaults.distanceRate(stored: null, unitedStates: false, usDefault: 0.73),
      0,
    );
    expect(
      LocaleDefaults.distanceRate(stored: null, unitedStates: true, usDefault: 0.73),
      0.73,
    );
    expect(LocaleDefaults.isUnitedStates('US'), isTrue);
    expect(LocaleDefaults.isUnitedStates('NO'), isFalse);
    expect(LocaleDefaults.currencySymbolFor('en_US'), r'$');
  });

  test('money format puts a space after a letter symbol', () {
    expect(Money.format(12.5, r'$'), r'$12.50');
    expect(Money.format(12.5, 'kr', true), '12.50 kr');
  });

  test('a country sets the currency name, symbol, and distance word', () {
    final norway = Localities.byCode('NO');
    final unitedStates = Localities.byCode('US');
    expect(norway!.currencyName, 'Norwegian krone');
    expect(norway.symbol, 'kr');
    expect(norway.symbolAfter, isTrue);
    expect(norway.distanceUnit, 'km');
    expect(unitedStates!.currencyName, 'US dollar');
    expect(unitedStates.symbol, r'$');
    expect(unitedStates.distanceUnit, 'miles');
    expect(Localities.matching('norw').single.countryCode, 'NO');
  });

  test('odometer rules reject a backwards or oversized day', () {
    final now = DateTime(2026, 6, 1);
    expect(
      MileageRules.validate(
        startMileage: 100,
        endMileage: 90,
        date: now,
        now: now,
      ),
      MileageRules.endNotGreater,
    );
    expect(
      MileageRules.validate(
        startMileage: 0,
        endMileage: 1001,
        date: now,
        now: now,
      ),
      MileageRules.dailyCap,
    );
    expect(
      MileageRules.validate(
        startMileage: 10,
        endMileage: 40,
        date: now,
        now: now,
      ),
      isNull,
    );
  });

  test('receipt total is read with or without a dollar sign', () {
    final withDollar = ReceiptTextParser.parse('SHELL OIL\nTotal \$42.18\n');
    final withWords = ReceiptTextParser.parse('GROCERY\nTotal kr 12.50\n');
    expect(withDollar.amount, 42.18);
    expect(withWords.amount, 12.50);
  });

  test('network failures are the ones worth queueing', () {
    expect(
      isRetryableNetworkError(Exception('SocketException: Failed host lookup')),
      isTrue,
    );
    expect(
      isRetryableNetworkError(Exception('PostgrestException: RLS')),
      isFalse,
    );
  });
}
