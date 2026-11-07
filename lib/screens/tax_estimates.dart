import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ledger_math.dart';
import '../money.dart';
import '../services/user_settings.dart';
import '../theme/app_themes.dart';

class EstimatedTaxScreen extends StatefulWidget {
  @override
  EstimatedTaxScreenState createState() => EstimatedTaxScreenState();
}

class EstimatedTaxScreenState extends State<EstimatedTaxScreen> {
  String selectedPeriod = "";
  Map<String, dynamic>? taxEstimates;
  String error = "";

  double federalRate = 0.15;
  double stateRate = 0.05;
  double customMileageRate = 0.0;

  int federalRatePercentage = 15;
  int stateRatePercentage = 5;
  String currencySymbol = r'$';
  String currencyName = '';
  bool symbolAfter = false;
  String distanceUnit = 'km';
  final TextEditingController distanceRateController = TextEditingController();

  bool applyMileageToState = true;

  List<String> get periods {
    final currentYear = DateTime.now().year;
    final result = <String>[];
    for (int y = currentYear + 1; y >= 2024; y--) {
      for (int q = 4; q >= 1; q--) {
        result.add('Q$q $y');
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    loadUserRates();
  }

  @override
  void dispose() {
    distanceRateController.dispose();
    super.dispose();
  }

  Future<void> loadUserRates() async {
    try {
      final settings = await UserSettings.load();
      if (!mounted) return;
      setState(() {
        federalRate = settings.primaryRate;
        stateRate = settings.secondaryRate;
        federalRatePercentage = (settings.primaryRate * 100).round();
        stateRatePercentage = (settings.secondaryRate * 100).round();
        customMileageRate = settings.distanceRate;
        currencySymbol = settings.currencySymbol;
        currencyName = settings.currencyName;
        symbolAfter = settings.symbolAfter;
        distanceUnit = settings.distanceUnit;
        applyMileageToState = settings.applyDistanceToSecondary;
        distanceRateController.text = settings.distanceRate == 0
            ? ''
            : settings.distanceRate.toStringAsFixed(2);
      });
    } catch (e) {
      debugPrint("Error loading user rates: $e");
    }
  }

  Future<bool> saveUserRates() async {
    final parsed = parseDistanceRate(distanceRateController.text);
    if (parsed == null) {
      if (!mounted) return false;
      setState(() {
        error = 'Distance rate must be from 0 to 5.00.';
      });
      return false;
    }
    customMileageRate = parsed;
    federalRate = federalRatePercentage / 100.0;
    stateRate = stateRatePercentage / 100.0;
    try {
      await UserSettings.saveRates(
        primaryRate: federalRate,
        secondaryRate: stateRate,
        distanceRate: customMileageRate,
      );
      if (!mounted) return true;
      setState(() {
        error = '';
      });
      return true;
    } catch (e) {
      debugPrint("Error saving user rates: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimated Tax Calculator',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 20),
              _buildPeriodSelectDropdown(),
              SizedBox(height: 20),
              _buildRateInputs(),
              SizedBox(height: 10),
              SwitchListTile(
                title: Text('Apply distance deduction to the secondary tax'),
                value: applyMileageToState,
                onChanged: (val) {
                  setState(() {
                    applyMileageToState = val;
                  });
                  UserSettings.saveApplyDistanceToSecondary(val);
                  fetchData();
                },
                activeColor: AppThemes.primaryColor,
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    error,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (taxEstimates != null) _buildTaxEstimates(),
              if (taxEstimates == null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                      'No tax estimates available. Please select a period.'),
                ),
              SizedBox(height: 20),
              _buildCalculationInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelectDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedPeriod.isEmpty ? null : selectedPeriod,
      decoration: InputDecoration(
        labelText: 'Select Period',
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppThemes.primaryColor, width: 2.0),
        ),
      ),
      items: periods.map((String period) {
        return DropdownMenuItem<String>(
          value: period,
          child: Text(period),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedPeriod = newValue ?? "";
        });
        fetchData();
      },
    );
  }

  Widget _buildRateInputs() {
    final federalItems = List.generate(100, (index) => index + 1);
    final stateItems = List.generate(100, (index) => index + 1);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
            child: Text(
              currencyName.isEmpty
                  ? 'Set your country on the account screen to choose a currency.'
                  : 'Currency: $currencyName ($currencySymbol)',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: federalItems.contains(federalRatePercentage) ? federalRatePercentage : null,
          decoration: InputDecoration(
            labelText: 'Primary tax rate (%)',
            border: OutlineInputBorder(),
          ),
          items: federalItems.map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value%'),
            );
          }).toList(),
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                federalRatePercentage = newValue;
                federalRate = newValue / 100;
              });
              saveUserRates().then((saved) {
                if (saved) fetchData();
              });
            }
          },
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: stateItems.contains(stateRatePercentage) ? stateRatePercentage : null,
          decoration: InputDecoration(
            labelText: 'Secondary tax rate (%)',
            border: OutlineInputBorder(),
          ),
          items: stateItems.map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value%'),
            );
          }).toList(),
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                stateRatePercentage = newValue;
                stateRate = newValue / 100;
              });
              saveUserRates().then((saved) {
                if (saved) fetchData();
              });
            }
          },
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: distanceRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Distance rate (per ${distanceUnit == 'miles' ? 'mile' : distanceUnit})',
            helperText: 'From 0.01 to 5.00. For example, 0.70 or 3.50.',
            border: OutlineInputBorder(),
          ),
          onEditingComplete: () {
            saveUserRates().then((saved) {
              if (saved) fetchData();
            });
          },
        ),
      ],
    );
  }

  Future<void> fetchData() async {
    if (selectedPeriod.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      setState(() {
        error = "";
      });

      // Parse period to get date range
      final periodDates = _getPeriodDates(selectedPeriod);
      if (periodDates == null) {
        setState(() {
          error = "Invalid period selected";
        });
        return;
      }

      final startDate = periodDates['start'];
      final endDate = periodDates['end'];
      if (startDate == null || endDate == null) {
        setState(() {
          error = "Invalid period selected (missing date)";
        });
        return;
      }

      // Fetch data for the selected period in parallel
      final results = await Future.wait([
        Supabase.instance.client
            .from('expenses')
            .select()
            .eq('user_id', user.id)
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String()),
        Supabase.instance.client
            .from('income')
            .select()
            .eq('user_id', user.id)
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String()),
        Supabase.instance.client
            .from('mileage')
            .select()
            .eq('user_id', user.id)
            .gte('start_date', startDate.toIso8601String())
            .lte('start_date', endDate.toIso8601String()),
      ]);

      final expenses = results[0] as List;
      final income = results[1] as List;
      final mileage = results[2] as List;

      // Calculate totals
      double totalIncome = income.fold(0.0, (total, item) => total + (item['amount'] ?? 0.0));
      double totalExpenses = expenses.fold(0.0, (total, item) => total + (item['amount'] ?? 0.0));
      final mileageMaps = (mileage)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final miles = sumDistance(mileageMaps);
      final totalMileageDeduction = miles * customMileageRate;

      setState(() {
        taxEstimates = {
          'totalIncome': totalIncome,
          'totalExpenses': totalExpenses,
          'totalMileageDeduction': totalMileageDeduction,
          'miles': miles,
        };
      });
    } catch (e) {

      setState(() {
        error = "Error fetching data: $e";
      });
    }
  }

  Map<String, DateTime>? _getPeriodDates(String period) {
    final year = int.parse(period.split(' ')[1]);
    final quarter = int.parse(period.split(' ')[0].substring(1));
    
    final startMonth = (quarter - 1) * 3 + 1;
    final endMonth = quarter * 3;
    
    return {
      'start': DateTime(year, startMonth, 1),
      'end': DateTime(year, endMonth + 1, 0), // Last day of the month
    };
  }

  Widget _buildTaxEstimates() {
    final miles = taxEstimates?['miles'] ?? 0;
    final totalIncome = (taxEstimates?['totalIncome'] ?? 0.0) as num;
    final totalExpenses = (taxEstimates?['totalExpenses'] ?? 0.0) as num;
    final estimate = SetAsideEstimate.compute(
      income: totalIncome.toDouble(),
      expenses: totalExpenses.toDouble(),
      distance: miles is int ? miles : (miles as num).round(),
      distanceRate: customMileageRate,
      primaryRate: federalRate,
      secondaryRate: stateRate,
      applyDistanceToSecondary: applyMileageToState,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tax Estimates for $selectedPeriod',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        _buildEstimateBlock(
          label: 'Income only',
          formula: 'No deductions',
          federal: estimate.onIncome.primary,
          state: estimate.onIncome.secondary,
          base: estimate.onIncome.base,
        ),
        SizedBox(height: 8),
        _buildEstimateBlock(
          label: 'After expenses',
          formula: 'Income − expenses',
          federal: estimate.afterExpenses.primary,
          state: estimate.afterExpenses.secondary,
          base: estimate.afterExpenses.base,
        ),
        SizedBox(height: 8),
        _buildEstimateBlock(
          label: 'After expenses and distance',
          formula: 'Income − expenses − distance',
          federal: estimate.afterDistance.primary,
          state: estimate.afterDistance.secondary,
          base: estimate.afterDistance.base,
          miles: miles is int ? miles : (miles as num).round(),
          mileageDeduction: estimate.distanceDeduction,
        ),
      ],
    );
  }

  Widget _buildEstimateBlock({
    required String label,
    required String formula,
    required double federal,
    required double state,
    required double base,
    int miles = 0,
    double mileageDeduction = 0.0,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text(formula, style: Theme.of(context).textTheme.bodySmall),
            SizedBox(height: 8),
            Text('Taxable base: ${Money.format(base, currencySymbol, symbolAfter)}'),
            if (miles > 0)
              Text(
                'Distance deduction: $miles $distanceUnit (${Money.format(mileageDeduction, currencySymbol, symbolAfter)})',
              ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Primary tax:', style: Theme.of(context).textTheme.bodyLarge),
                Text(Money.format(federal, currencySymbol, symbolAfter), style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Secondary tax:', style: Theme.of(context).textTheme.bodyLarge),
                Text(Money.format(state, currencySymbol, symbolAfter), style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculation Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Text(
              'Primary and secondary are the two rates you set. The distance rate is an amount per mile or kilometer, from 0.01 to 5.00. '
              'If fuel, insurance, or repairs are already in your expenses, do not also count that distance in the third figure. '
              'These are set-aside estimates. A tax professional files the return.',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
