import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math' as math;
import '../mileage_rates.dart' as MileageRates;

class MileageCalculator {
  List<MileageRates.MileageRate> mileageRates = [];

  MileageCalculator() {
    mileageRates = MileageRates.mileageRates;
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
  _EstimatedTaxScreenState createState() => _EstimatedTaxScreenState();
}

class _EstimatedTaxScreenState extends State<EstimatedTaxScreen> {
  User? user;
  String selectedPeriod = "";
  Map<String, dynamic>? taxEstimates;
  String error = "";

  final double IRS_RATE = 0.15;
  final double STATE_RATE = 0.05;

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
    user = FirebaseAuth.instance.currentUser;
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

  Future<void> fetchData() async {
    if (user == null || selectedPeriod.isEmpty) {
      setState(() {
        error = "User or selected period not selected.";
      });
      return;
    }

    try {
      final expenses = await getExpenses();
      final income = await getIncome();
      final mileage = await getMileageEntries();

      calculateTaxEstimates(expenses, income, mileage);
      setState(() {
        error = "";
      });
    } catch (err) {
      setState(() {
        error = "Failed to fetch data. Please try again.";
      });
      Fluttertoast.showToast(msg: 'Error fetching data. Please try again.');
    }
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final periodStart = Timestamp.fromDate(getPeriodStart());
    final periodEnd = Timestamp.fromDate(getPeriodEnd());

    final q = FirebaseFirestore.instance
        .collection('expenses')
        .where('uid', isEqualTo: user!.uid)
        .where('date', isGreaterThanOrEqualTo: periodStart)
        .where('date', isLessThanOrEqualTo: periodEnd);

    final querySnapshot = await q.get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getIncome() async {
    final periodStart = Timestamp.fromDate(getPeriodStart());
    final periodEnd = Timestamp.fromDate(getPeriodEnd());

    final q = FirebaseFirestore.instance
        .collection('income')
        .where('uid', isEqualTo: user!.uid)
        .where('date', isGreaterThanOrEqualTo: periodStart)
        .where('date', isLessThanOrEqualTo: periodEnd);

    final querySnapshot = await q.get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getMileageEntries() async {
    final periodStart = getPeriodStart();
    final periodEnd = getPeriodEnd();

    final q = FirebaseFirestore.instance
        .collection('drivermileage')
        .where('uid', isEqualTo: user!.uid)
        .where('startDate', isGreaterThanOrEqualTo: periodStart)
        .where('startDate', isLessThanOrEqualTo: periodEnd);

    final querySnapshot = await q.get();
    return querySnapshot.docs
        .map((doc) => {
              ...doc.data(),
              'startDate': (doc['startDate'] as Timestamp).toDate(),
              'endDate': (doc['endDate'] as Timestamp).toDate(),
            })
        .toList();
  }

  DateTime getPeriodStart() {
    final parts = selectedPeriod.split(' ');
    final quarter = parts[0];
    final year = int.parse(parts[1]);

    int month = (int.parse(quarter.substring(1)) - 1) * 3 + 1;
    return DateTime(year, month, 1);
  }

  DateTime getPeriodEnd() {
    final parts = selectedPeriod.split(' ');
    final quarter = parts[0];
    final year = int.parse(parts[1]);

    int month = int.parse(quarter.substring(1)) * 3;
    return DateTime(year, month, 0, 23, 59, 59, 999);
  }

  void calculateTaxEstimates(List<Map<String, dynamic>> expenses,
      List<Map<String, dynamic>> income, List<Map<String, dynamic>> mileage) {
    double totalIncome =
        income.fold(0, (sum, item) => sum + (item['amount'] ?? 0));
    double totalExpenses =
        expenses.fold(0, (sum, item) => sum + (item['amount'] ?? 0));
    double totalMileageDeduction = calculateMileageDeduction(mileage);

    Map<String, double> grossTaxEstimate = {
      'irs': totalIncome * IRS_RATE,
      'state': totalIncome * STATE_RATE,
    };

    double netIncomeNoMileage = totalIncome - totalExpenses;
    Map<String, double> netTaxEstimateNoMileage = {
      'irs': math.max(0, netIncomeNoMileage * IRS_RATE),
      'state': math.max(0, netIncomeNoMileage * STATE_RATE),
    };

    double netIncomeWithMileage =
        totalIncome - totalExpenses - totalMileageDeduction;
    Map<String, double> netTaxEstimate = {
      'irs': math.max(0, netIncomeWithMileage * IRS_RATE),
      'state': math.max(0, netIncomeWithMileage * STATE_RATE),
    };

    setState(() {
      taxEstimates = {
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'totalMileageDeduction': totalMileageDeduction,
        'grossTaxEstimate': grossTaxEstimate,
        'netTaxEstimateNoMileage': netTaxEstimateNoMileage,
        'netTaxEstimate': netTaxEstimate,
      };
    });
  }

  double calculateMileageDeduction(List<Map<String, dynamic>> mileage) {
    double totalDeduction = 0;
    for (var entry in mileage) {
      if (entry['startMileage'] != null &&
          entry['endMileage'] != null &&
          entry['startDate'] != null) {
        final milesDriven =
            (entry['endMileage'] as num) - (entry['startMileage'] as num);
        final rate = mileageCalculator.getMileageRate(entry['startDate']);
        final deduction = milesDriven * rate;
        totalDeduction += deduction;
        print(
            "Mileage entry: Miles: $milesDriven, Rate: $rate, Deduction: $deduction");
      } else {
        print("Warning: Invalid mileage entry: $entry");
      }
    }
    print("Total mileage deduction: $totalDeduction");
    return totalDeduction;
  }

  Widget _buildTaxEstimates() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tax Estimates for $selectedPeriod',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Text(
              'Total Income: \$${taxEstimates!['totalIncome'].toStringAsFixed(2)}',
              style: TextStyle(color: AppThemes.primaryColor),
            ),
            Text(
              'Total Expenses: \$${taxEstimates!['totalExpenses'].toStringAsFixed(2)}',
              style: TextStyle(color: Colors.red),
            ),
            Text(
              'Total Mileage Deduction: \$${taxEstimates!['totalMileageDeduction'].toStringAsFixed(2)}',
              style: TextStyle(color: Colors.green),
            ),
            Divider(),
            Text('1. Gross Tax Estimate',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'IRS Payment: \$${taxEstimates!['grossTaxEstimate']['irs'].toStringAsFixed(2)}',
            ),
            Text(
              'State Payment: \$${taxEstimates!['grossTaxEstimate']['state'].toStringAsFixed(2)}',
            ),
            SizedBox(height: 8),
            Text('2. Net Tax Estimate (Without Mileage Deductions)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'IRS Payment: \$${taxEstimates!['netTaxEstimateNoMileage']['irs'].toStringAsFixed(2)}',
            ),
            Text(
              'State Payment: \$${taxEstimates!['netTaxEstimateNoMileage']['state'].toStringAsFixed(2)}',
            ),
            SizedBox(height: 8),
            Text('3. Net Tax Estimate (With Mileage Deductions)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'IRS Payment: \$${taxEstimates!['netTaxEstimate']['irs'].toStringAsFixed(2)}',
            ),
            Text(
              'State Payment: \$${taxEstimates!['netTaxEstimate']['state'].toStringAsFixed(2)}',
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
        child: Text(
          "This estimate uses an IRS rate of 15% and a state rate of 5%.\n"
          "Gross Tax Estimate is the total income * IRS rate (15%) and total income * state rate (5%).\n"
          "Net Tax Estimate (Without Mileage Deductions) is the total income less expenses * IRS rate (15%) and total income * state rate (5%).\n"
          "Net Tax Estimate (With Mileage Deductions) is the total income less expenses and less mileage deduction * IRS rate (15%) and total income * state rate (5%).",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
