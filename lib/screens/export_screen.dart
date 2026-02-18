import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_themes.dart';

class ExportScreen extends StatefulWidget {
  @override
  ExportScreenState createState() => ExportScreenState();
}

class ExportScreenState extends State<ExportScreen> {
  final supabase = Supabase.instance.client;
  final User? user = Supabase.instance.client.auth.currentUser;

  int selectedYear = DateTime.now().year;
  String error = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppThemes.buildAppBar(context, 'RideWealth Assistant'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Data',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: 16),
            DropdownButton<int>(
              value: selectedYear,
              onChanged: (int? newValue) {
                setState(() {
                  selectedYear = newValue!;
                });
              },
              items:
              List.generate(5, (index) => DateTime.now().year - index + 2)
                  .map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleExport,
              child: Text('Export Financial Data'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: handleMileageExport,
              child: Text('Export Mileage'),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> handleExport() async {
    print('Starting export process...');
    if (!userAuthenticated()) {
      print('User not authenticated');
      setState(() {
        error = 'User not authenticated';
      });
      return;
    }

    try {
      print('Fetching expenses...');
      final expenses = await fetchExpenses();
      print('Fetched ${expenses.length} expenses');

      print('Fetching income...');
      final income = await fetchIncome();
      print('Fetched ${income.length} income records');

      print('Fetching mileage...');
      final mileage = await fetchMileage();
      print('Fetched ${mileage.length} mileage records');

      print('Generating export data...');
      final exportData = generateExportData(expenses, income, mileage);
      print('Export data generated: ${exportData.length} rows');

      print('Opening CSV...');
      await openCsvRows(exportData, 'export_data.csv');
      print('CSV process completed');
    } catch (err) {
      print('Error during export: $err');
      setState(() {
        error = 'Failed to export data. Please try again.';
      });
    }
  }

  bool userAuthenticated() {
    return user != null;
  }

  Future<void> handleMileageExport() async {
    print('Starting mileage export process...');
    if (!userAuthenticated()) {
      print('User not authenticated');
      setState(() {
        error = 'User not authenticated';
      });
      return;
    }

    try {
      print('Fetching mileage...');
      final mileage = await fetchMileage();
      print('Fetched mileage:');
      for (var i = 0; i < mileage.length; i++) {
        print('Mileage $i: ${mileage[i]}');
      }
      print('Fetched ${mileage.length} mileage records');
      final formattedMileage = formatMileageForExport(mileage);
      print('Formatted mileage: $formattedMileage');
      print('Opening CSV...');
      await openCsv(formattedMileage, 'mileage_data.csv');
      print('CSV process completed');
    } catch (err, stack) {
      print('Error during mileage export: $err');
      print('Stack trace: $stack');
      setState(() {
        error = 'Failed to export mileage data. Please try again.';
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    final startOfYear = DateTime(selectedYear, 1, 1);
    final endOfYear = DateTime(selectedYear, 12, 31, 23, 59, 59);

    final response = await supabase
        .from('expenses')
        .select()
        .eq('user_id', user!.id)
        .gte('date', startOfYear.toIso8601String())
        .lte('date', endOfYear.toIso8601String());

    return (response as List).map((doc) {
      final data = doc;
      data['date'] = DateTime.parse(data['date']);
      return data;
    }).cast<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchIncome() async {
    final startOfYear = DateTime(selectedYear, 1, 1);
    final endOfYear = DateTime(selectedYear, 12, 31, 23, 59, 59);

    final response = await supabase
        .from('income')
        .select()
        .eq('user_id', user!.id)
        .gte('date', startOfYear.toIso8601String())
        .lte('date', endOfYear.toIso8601String());

    return (response as List).map((doc) {
      final data = doc;
      data['date'] = DateTime.parse(data['date']);
      return data;
    }).cast<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchMileage() async {
    final startOfYear = DateTime(selectedYear, 1, 1);
    final endOfYear = DateTime(selectedYear, 12, 31, 23, 59, 59);

    print('Querying mileage for user: $user!.id, start: $startOfYear, end: $endOfYear');
    final response = await supabase
        .from('mileage')
        .select()
        .eq('user_id', user!.id)
        .gte('start_date', startOfYear.toIso8601String())
        .lte('start_date', endOfYear.toIso8601String());
    print('Raw mileage response: $response.runtimeType $response');

    try {
      return (response as List).map((doc) {
        final data = doc;
        data['start_date'] = DateTime.parse(data['start_date']);
        data['end_date'] = DateTime.parse(data['end_date']);
        return data;
      }).cast<Map<String, dynamic>>().toList();
    } catch (e) {
      print('Error parsing mileage records: $e');
      print('Problematic response: $response');
      rethrow;
    }
  }

  // List of all expense categories
  static const List<String> expenseCategories = [
    "Advertising",
    "Car and truck expenses",
    "Commissions and fees",
    "Contract labor",
    "Depletion",
    "Depreciation and section 179 expense",
    "Employee benefit programs",
    "Insurance (other than health)",
    "Interest (Other)",
    "Mortgage",
    "Legal and professional services",
    "Office expense",
    "Pension and profit-sharing plans",
    "Rent or lease (Vehicles, machinery, equipment)",
    "Rent or lease (Other business property)",
    "Repairs and maintenance",
    "Supplies",
    "Taxes and licenses",
    "Travel",
    "Meals",
    "Utilities",
    "Wages",
    "Estimated Tax Payment",
    "Other expenses"
  ];

  List<List<dynamic>> generateExportData(
      List<Map<String, dynamic>> expenses,
      List<Map<String, dynamic>> income,
      List<Map<String, dynamic>> mileage) {
    double totalIncome = income.fold(0.0, (total, item) => total + ((item['amount'] ?? 0) as num).toDouble());
    double totalExpenses = expenses.fold(0.0, (total, item) => total + ((item['amount'] ?? 0) as num).toDouble());
    double mileageDeduction = _calculateMileageDeduction(mileage);
    double netIncome = totalIncome - totalExpenses - mileageDeduction;

    // Calculate totals by category
    Map<String, double> categoryTotals = {};
    double estimatedTaxPaymentIRS = 0.0;
    double estimatedTaxPaymentState = 0.0;
    
    for (var category in expenseCategories) {
      categoryTotals[category] = 0.0;
    }
    
    for (var expense in expenses) {
      String category = expense['category'] ?? 'Other expenses';
      double amount = ((expense['amount'] ?? 0) as num).toDouble();
      
      if (category == 'Estimated Tax Payment') {
        // Try to determine if it's IRS or State based on description
        String description = (expense['description'] ?? '').toString().toLowerCase();
        if (description.contains('state') || description.contains('state tax')) {
          estimatedTaxPaymentState += amount;
        } else {
          // Default to IRS if not clearly marked as state
          estimatedTaxPaymentIRS += amount;
        }
      } else {
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
      }
    }

    // Build CSV rows
    List<List<dynamic>> rows = [];
    
    // Summary section
    rows.add(['Total Income', totalIncome.toStringAsFixed(2)]);
    rows.add(['Total Expenses', totalExpenses.toStringAsFixed(2)]);
    rows.add(['Total Mileage Deduction', mileageDeduction.toStringAsFixed(2)]);
    rows.add(['Net Income', netIncome.toStringAsFixed(2)]);
    rows.add([]); // Empty row for spacing
    
    // Expense Categories section
    rows.add(['Expense Categories']);
    for (var category in expenseCategories) {
      if (category != 'Estimated Tax Payment') {
        double total = categoryTotals[category] ?? 0.0;
        rows.add([category, total.toStringAsFixed(2)]);
      }
    }
    rows.add([]); // Empty row for spacing
    
    // Estimated Payments section
    rows.add(['Estimated Payments to IRS', estimatedTaxPaymentIRS.toStringAsFixed(2)]);
    rows.add(['Estimated Payments to State', estimatedTaxPaymentState.toStringAsFixed(2)]);
    
    return rows;
  }

  double _calculateMileageDeduction(List<Map<String, dynamic>> mileage) {
    const rate = 0.655;
    return mileage.fold(0, (total, entry) {
      int miles = entry['end_mileage'] - entry['start_mileage'];
      return total + (miles * rate);
    });
  }

  List<Map<String, String>> formatMileageForExport(
      List<Map<String, dynamic>> mileage) {
    return mileage
        .map((entry) => {
      'Date': DateFormat.yMd().format(entry['start_date']),
      'Start Mileage': entry['start_mileage'].toString(),
      'End Mileage': entry['end_mileage'].toString(),
      'Total Daily Miles/Km':
          (entry['end_mileage'] - entry['start_mileage']).toString()
    })
        .toList();
  }

  Future<void> openCsvRows(List<List<dynamic>> rows, String filename) async {
    print('Starting openCsvRows...');
    if (rows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    String csvString = csv.encode(rows);
    print('CSV converted: $csvString');

    if (kIsWeb) {
      print('Processing for web platform...');
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      print('Web download initiated');
    } else {
      print('Processing for mobile platform...');
      try {
        final directory = await _getDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsString(csvString);
        print('File saved to: ${file.path}');

        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        final rect = box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null;

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: filename,
            sharePositionOrigin: rect,
          ),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV file saved and ready to share')),
        );
      } catch (e) {
        print('Error handling CSV: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error with CSV file: $e')),
        );
      }
    }
    print('openCsvRows completed');
  }

  Future<void> openCsv(List<Map<String, dynamic>> data, String filename) async {
    print('Starting openCsv...');
    if (data.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    List<List<dynamic>> rows = [
      data.first.keys.toList(),
      ...data.map((item) => item.values.map((v) => v ?? 0).toList())
    ];
    print('Rows prepared: $rows');

    await openCsvRows(rows, filename);
  }

  Future<Directory> _getDirectory() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted &&
          await Permission.manageExternalStorage.request().isGranted) {
        return Directory('/storage/emulated/0/Download');
      }
      return await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<void> saveToFile(List<Map<String, dynamic>> data, int year) async {
    if (kIsWeb) {
      // Web export
      final csvData = _convertToCsvFormat(data);
      final csvString = csv.encode(csvData);
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'ridewealth_export_$year.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile export
      final status = await Permission.storage.request();
      if (status.isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/ridewealth_export_$year.csv');
        final csvData = _convertToCsvFormat(data);
        final csvString = csv.encode(csvData);
        await file.writeAsString(csvString);
        
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'RideWealth Export Data for $year',
          ),
        );
      }
    }
  }

  List<List<dynamic>> _convertToCsvFormat(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [];
    
    // Get headers from the first row
    final headers = data.first.keys.toList();
    final rows = <List<dynamic>>[];
    
    // Add header row
    rows.add(headers);
    
    // Add data rows
    for (final row in data) {
      rows.add(headers.map((header) => row[header]).toList());
    }
    
    return rows;
  }
}