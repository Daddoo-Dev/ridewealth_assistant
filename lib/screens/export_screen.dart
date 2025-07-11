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
      appBar: AppBar(
        title: Text('RideWealth Assistant'),
      ),
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
                  style: TextStyle(color: Colors.red),
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
      print('Export data generated: ${exportData.toString()}');

      print('Opening CSV...');
      await openCsv(exportData, 'export_data.csv');
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

    print('Querying mileage for user: ${user!.id}, start: ${startOfYear.toIso8601String()}, end: ${endOfYear.toIso8601String()}');
    final response = await supabase
        .from('mileage')
        .select()
        .eq('user_id', user!.id)
        .gte('start_date', startOfYear.toIso8601String())
        .lte('start_date', endOfYear.toIso8601String());
    print('Raw mileage response: ${response.runtimeType} ${response}');

    try {
      return (response as List).map((doc) {
        final data = doc;
        data['start_date'] = DateTime.parse(data['start_date']);
        data['end_date'] = DateTime.parse(data['end_date']);
        return data;
      }).cast<Map<String, dynamic>>().toList();
    } catch (e) {
      print('Error parsing mileage records: ${e}');
      print('Problematic response: ${response}');
      rethrow;
    }
  }

  List<Map<String, dynamic>> generateExportData(
      List<Map<String, dynamic>> expenses,
      List<Map<String, dynamic>> income,
      List<Map<String, dynamic>> mileage) {
    double totalIncome = income.fold(0, (total, item) => total + (item['amount'] ?? 0));
    double totalExpenses = expenses.fold(0, (total, item) => total + (item['amount'] ?? 0));
    double mileageDeduction = _calculateMileageDeduction(mileage);

    return [
      {
        'Total Income': totalIncome,
        'Total Expenses': totalExpenses,
        'Total Mileage Deduction': mileageDeduction,
        'Net Income': totalIncome - totalExpenses - mileageDeduction,
      }
    ];
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
      'Total Daily Miles':
      (entry['end_mileage'] - entry['start_mileage']).toString()
    })
        .toList();
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
    print('Rows prepared: ${rows.toString()}');

    String csv = const ListToCsvConverter().convert(rows);
    print('CSV converted: $csv');

    if (kIsWeb) {
      print('Processing for web platform...');
      final bytes = utf8.encode(csv);
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
        await file.writeAsString(csv);
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
    print('openCsv completed');
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
      final csv = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csv);
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
        final csv = const ListToCsvConverter().convert(csvData);
        await file.writeAsString(csv);
        
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