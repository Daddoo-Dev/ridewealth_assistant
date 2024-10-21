import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../mileage_rates.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportScreen extends StatefulWidget {
  @override
  _ExportScreenState createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  int selectedYear = DateTime.now().year;
  String error = '';
  String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<Map<String, dynamic>> exportData = [];

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
    if (!userAuthenticated()) {
      setState(() {
        error = 'User not authenticated';
      });
      return;
    }

    try {
      final expenses = await fetchExpenses();
      final income = await fetchIncome();
      final mileage = await fetchMileage();
      setState(() {
        exportData = generateExportData(expenses, income, mileage);
      });
      downloadCsv(exportData);
    } catch (err) {
      setState(() {
        error = 'Failed to export data. Please try again.';
      });
    }
  }

  Future<void> handleMileageExport() async {
    if (!userAuthenticated()) {
      setState(() {
        error = 'User not authenticated';
      });
      return;
    }

    try {
      final mileage = await fetchMileage();
      final formattedMileage = formatMileageForExport(mileage);
      downloadMileageCsv(formattedMileage);
    } catch (err) {
      setState(() {
        error = 'Failed to export mileage data. Please try again.';
      });
    }
  }

  bool userAuthenticated() {
    return uid.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    final startOfYear = DateTime(selectedYear, 1, 1);
    final endOfYear = DateTime(selectedYear, 12, 31, 23, 59, 59);

    final querySnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: startOfYear)
        .where('date', isLessThanOrEqualTo: endOfYear)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['date'] = (data['date'] as Timestamp).toDate();
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchIncome() async {
    final startOfYear = DateTime(selectedYear, 1, 1);
    final endOfYear = DateTime(selectedYear, 12, 31, 23, 59, 59);

    final querySnapshot = await FirebaseFirestore.instance
        .collection('income')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: startOfYear)
        .where('date', isLessThanOrEqualTo: endOfYear)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['date'] = (data['date'] as Timestamp).toDate();
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchMileage() async {
    final startOfYear = DateTime(selectedYear, 1, 1);
    final endOfYear = DateTime(selectedYear, 12, 31, 23, 59, 59);

    final querySnapshot = await FirebaseFirestore.instance
        .collection('drivermileage')
        .where('uid', isEqualTo: uid)
        .where('startDate', isGreaterThanOrEqualTo: startOfYear)
        .where('startDate', isLessThanOrEqualTo: endOfYear)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['startDate'] = (data['startDate'] as Timestamp).toDate();
      data['endDate'] = (data['endDate'] as Timestamp).toDate();
      return data;
    }).toList();
  }

  List<Map<String, dynamic>> generateExportData(
      List<Map<String, dynamic>> expenses,
      List<Map<String, dynamic>> income,
      List<Map<String, dynamic>> mileage) {
    double totalIncome =
        income.fold(0, (sum, item) => sum + (item['amount'] ?? 0));
    double totalExpenses =
        expenses.fold(0, (sum, item) => sum + (item['amount'] ?? 0));
    double mileageDeduction = mileage.fold(0, (sum, entry) {
      int miles = entry['endMileage'] - entry['startMileage'];
      return sum + (miles * getMileageRate(entry['startDate']));
    });

    return [
      {
        'Year': selectedYear,
        'Income': totalIncome,
        'Expenses': totalExpenses,
        'Mileage Deduction': mileageDeduction
      }
    ];
  }

  double getMileageRate(DateTime date) {
    for (var ratePeriod in mileageRates) {
      if (date.isAfter(ratePeriod.startDate) &&
          date.isBefore(ratePeriod.endDate)) {
        return ratePeriod.rate;
      }
    }
    // If no matching period is found, return the most recent rate
    return mileageRates.last.rate;
  }

  List<Map<String, String>> formatMileageForExport(
      List<Map<String, dynamic>> mileage) {
    return mileage
        .map((entry) => {
              'Date': DateFormat.yMd().format(entry['startDate']),
              'Start Mileage': entry['startMileage'].toString(),
              'End Mileage': entry['endMileage'].toString(),
              'Total Daily Miles':
                  (entry['endMileage'] - entry['startMileage']).toString()
            })
        .toList();
  }

  void downloadCsv(List<Map<String, dynamic>> data) {
    List<List<dynamic>> rows = [];
    rows.add(data.first.keys.toList()); // Adding header
    for (var element in data) {
      rows.add(element.values.toList());
    }

    String csv = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      // Web platform
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "export_data.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile platform
      _saveCsvFile(csv, "export_data.csv");
    }
  }

  void downloadMileageCsv(List<Map<String, String>> data) {
    List<List<dynamic>> rows = [];
    rows.add(data.first.keys.toList()); // Adding header
    for (var element in data) {
      rows.add(element.values.toList());
    }

    String csv = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      // Web platform
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "mileage_data.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile platform
      _saveCsvFile(csv, "mileage_data.csv");
    }
  }

  Future<void> _saveCsvFile(String csv, String fileName) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        if (await Permission.storage.request().isGranted) {
          if (await Permission.manageExternalStorage.request().isGranted) {
            directory = Directory('/storage/emulated/0/Download');
          } else {
            directory = await getExternalStorageDirectory();
          }
          if (directory != null) {
            String newPath = "";
            List<String> paths = directory.path.split("/");
            for (int x = 1; x < paths.length; x++) {
              String folder = paths[x];
              if (folder != "Android") {
                newPath += "/" + folder;
              } else {
                break;
              }
            }
            newPath = newPath + "/Download";
            directory = Directory(newPath);
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Unable to access storage directory');
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV file saved to ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save CSV file: $e')),
      );
    }
  }
}
