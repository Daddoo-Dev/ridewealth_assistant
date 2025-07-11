import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mileage_rates.dart' as mileage_rates;

class MileageCalculator {
  List<mileage_rates.MileageRate> mileageRates = [];

  MileageCalculator() {
    mileageRates = mileage_rates.mileageRates;
  }

  double getMileageRate(DateTime date) {
    for (var rate in mileageRates.reversed) {
      if (date.isAfter(rate.startDate) ||
          date.isAtSameMomentAs(rate.startDate)) {
        return rate.rate;
      }
    }
    print(
        "Warning: No applicable rate found for date $date. Using most recent rate.");
    return mileageRates.last.rate;
  }
}

class EstimatedTaxScreen extends StatefulWidget {
  @override
  EstimatedTaxScreenState createState() => EstimatedTaxScreenState();
}

class EstimatedTaxScreenState extends State<EstimatedTaxScreen> {
  User? user;
  String selectedPeriod = "";
  Map<String, dynamic>? taxEstimates;
  String error = "";

  double federalRate = 0.15;
  double stateRate = 0.05;
  double customMileageRate = 0.0;

  int federalRatePercentage = 15;
  int stateRatePercentage = 5;
  int customMileageRateCents = 0;

  bool applyMileageToState = true;

  final List<String> periods = [
    "Q1 2024",
    "Q2 2024",
    "Q3 2024",
    "Q4 2024",
    "Q1 2025",
    "Q2 2025",
    "Q3 2025",
    "Q4 2025",
  ];

  final MileageCalculator mileageCalculator = MileageCalculator();

  @override
  void initState() {
    super.initState();
    user = Supabase.instance.client.auth.currentUser;
    loadUserRates();
  }

  Future<void> loadUserRates() async {
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user!.id)
            .single();

        var data = response;
        setState(() {
          federalRatePercentage = ((data['federalRate'] ?? 0.15) * 100).round();
          stateRatePercentage = ((data['stateRate'] ?? 0.05) * 100).round();
          customMileageRateCents = ((data['customMileageRate'] ??
                      mileageCalculator.getMileageRate(DateTime.now())) *
                  100)
              .round();

          federalRate = federalRatePercentage / 100;
          stateRate = stateRatePercentage / 100;
          customMileageRate = customMileageRateCents / 100;
        });
      } catch (e) {
        print("Error loading user rates: $e");
      }
    }
  }

  Future<void> saveUserRates() async {
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('users')
            .upsert({
          'id': user!.id,
          'federalRate': federalRate,
          'stateRate': stateRate,
          'customMileageRate': customMileageRate,
        });
      } catch (e) {
        print("Error saving user rates: $e");
      }
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
                title: Text('Apply mileage deduction to state tax'),
                value: applyMileageToState,
                onChanged: (val) {
                  setState(() {
                    applyMileageToState = val;
                    fetchData();
                  });
                },
                activeColor: AppThemes.primaryColor,
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    error,
                    style: TextStyle(color: Colors.red),
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
          fetchData();
        });
      },
    );
  }

  Widget _buildRateInputs() {
    final federalItems = List.generate(100, (index) => index + 1);
    final stateItems = List.generate(100, (index) => index + 1);
    final mileageItems = List.generate(100, (index) => index + 1);
    return Column(
      children: [
        DropdownButtonFormField<int>(
          value: federalItems.contains(federalRatePercentage) ? federalRatePercentage : null,
          decoration: InputDecoration(
            labelText: 'Federal Tax Rate (%)',
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
                saveUserRates();
                fetchData();
              });
            }
          },
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: stateItems.contains(stateRatePercentage) ? stateRatePercentage : null,
          decoration: InputDecoration(
            labelText: 'State Tax Rate (%)',
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
                saveUserRates();
                fetchData();
              });
            }
          },
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: mileageItems.contains(customMileageRateCents) ? customMileageRateCents : null,
          decoration: InputDecoration(
            labelText: 'Custom Mileage Rate (cents)',
            border: OutlineInputBorder(),
          ),
          items: mileageItems.map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value¢'),
            );
          }).toList(),
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                customMileageRateCents = newValue;
                customMileageRate = newValue / 100;
                saveUserRates();
                fetchData();
              });
            }
          },
        ),
      ],
    );
  }

  Future<void> fetchData() async {
    if (selectedPeriod.isEmpty) return;

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

      print('DEBUG: user id: ${user?.id}');
      print('DEBUG: startDate: ${startDate.toIso8601String()}');
      print('DEBUG: endDate: ${endDate.toIso8601String()}');

      // Fetch data for the selected period
      final expensesResponse = await Supabase.instance.client
          .from('expenses')
          .select()
          .eq('user_id', user!.id)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      final incomeResponse = await Supabase.instance.client
          .from('income')
          .select()
          .eq('user_id', user!.id)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      final mileageResponse = await Supabase.instance.client
          .from('mileage')
          .select()
          .eq('user_id', user!.id)
          .gte('start_date', startDate.toIso8601String())
          .lte('start_date', endDate.toIso8601String());

      print('DEBUG: expensesResponse: $expensesResponse');
      print('DEBUG: incomeResponse: $incomeResponse');
      print('DEBUG: mileageResponse: $mileageResponse');

      final expenses = expensesResponse as List;
      final income = incomeResponse as List;
      final mileage = mileageResponse as List;

      // Calculate totals
      double totalIncome = income.fold(0.0, (total, item) => total + (item['amount'] ?? 0.0));
      double totalExpenses = expenses.fold(0.0, (total, item) => total + (item['amount'] ?? 0.0));
      double totalMileageDeduction = _calculateMileageDeduction(mileage);
      int miles = mileage.fold(0, (total, item) => total + (((item['end_mileage'] ?? 0) - (item['start_mileage'] ?? 0)) as int));

      setState(() {
        taxEstimates = {
          'totalIncome': totalIncome,
          'totalExpenses': totalExpenses,
          'totalMileageDeduction': totalMileageDeduction,
          'miles': miles,
        };
      });
    } catch (e) {
      print('DEBUG: fetchData error: $e');
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

  double _calculateMileageDeduction(List mileage) {
    return mileage.fold(0.0, (total, entry) {
      final startMileage = entry['start_mileage'] ?? 0;
      final endMileage = entry['end_mileage'] ?? 0;
      final miles = endMileage - startMileage;
      final rate = customMileageRate > 0 ? customMileageRate : mileageCalculator.getMileageRate(DateTime.now());
      return total + (miles * rate);
    });
  }

  Widget _buildTaxEstimates() {
    final miles = taxEstimates?['miles'] ?? 0;
    final mileageDeduction = taxEstimates?['totalMileageDeduction'] ?? 0.0;
    final totalIncome = taxEstimates?['totalIncome'] ?? 0.0;
    final totalExpenses = taxEstimates?['totalExpenses'] ?? 0.0;

    // Conservative: No deductions
    final conservativeBase = totalIncome;
    final conservativeFederal = conservativeBase * federalRate;
    final conservativeState = conservativeBase * stateRate;

    // Moderate: Subtract expenses
    final moderateBase = totalIncome - totalExpenses;
    final moderateFederal = moderateBase * federalRate;
    final moderateState = moderateBase * stateRate;

    // Aggressive: Subtract expenses and mileage deduction
    final aggressiveBase = totalIncome - totalExpenses - mileageDeduction;
    final aggressiveFederal = aggressiveBase * federalRate;
    final aggressiveState = (applyMileageToState
        ? aggressiveBase
        : totalIncome - totalExpenses) * stateRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tax Estimates for $selectedPeriod',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        _buildEstimateBlock(
          label: 'Conservative',
          formula: 'No deductions',
          federal: conservativeFederal,
          state: conservativeState,
          base: conservativeBase,
        ),
        SizedBox(height: 8),
        _buildEstimateBlock(
          label: 'Moderate',
          formula: 'Income - Expenses',
          federal: moderateFederal,
          state: moderateState,
          base: moderateBase,
        ),
        SizedBox(height: 8),
        _buildEstimateBlock(
          label: 'Aggressive',
          formula: 'Income - Expenses - Mileage Deduction',
          federal: aggressiveFederal,
          state: aggressiveState,
          base: aggressiveBase,
          miles: miles,
          mileageDeduction: mileageDeduction,
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
            Text('Taxable Base: ' + base.toStringAsFixed(2)),
            if (miles > 0)
              Text('Mileage Deduction: $miles miles ( ${mileageDeduction.toStringAsFixed(2)})'),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Federal Tax:', style: Theme.of(context).textTheme.bodyLarge),
                Text(' ${federal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('State Tax:', style: Theme.of(context).textTheme.bodyLarge),
                Text(' ${state.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge),
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
              'This calculator provides estimates based on your current tax rates and mileage rates. '
              'Actual tax obligations may vary. Please consult with a tax professional for accurate tax planning.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
