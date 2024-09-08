import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class MileageScreen extends StatefulWidget {
  @override
  _MileageScreenState createState() => _MileageScreenState();
}

class _MileageScreenState extends State<MileageScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> mileages = [];
  TextEditingController startMileageController = TextEditingController();
  TextEditingController endMileageController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String error = "";
  bool showTransactions = false;
  Map<String, dynamic>? editingMileage;

  @override
  void initState() {
    super.initState();
    loadMileages();
    loadStoredStartMileage();
  }

  Future<void> loadMileages() async {
    if (_user == null) return;
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('drivermileage')
          .where("uid", isEqualTo: _user.uid)
          .orderBy("startDate", descending: true)
          .get();
      setState(() {
        mileages = querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    } catch (e) {
      print("Error loading mileages: $e");
      setState(() {
        error = "Failed to load mileages. Please try again.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load mileages. Please try again.")),
      );
    }
  }

  Future<void> loadStoredStartMileage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedStartMileage = prefs.getString('startMileage');
    if (storedStartMileage != null) {
      Map<String, dynamic> startMileageData = jsonDecode(storedStartMileage);
      setState(() {
        startMileageController.text = startMileageData['mileage'].toString();
        selectedDate = DateTime.parse(startMileageData['date']);
      });
    }
  }

  Future<void> saveStartMileage() async {
    if (startMileageController.text.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'startMileage',
          jsonEncode({
            'mileage': startMileageController.text,
            'date': selectedDate.toIso8601String(),
            'timestamp': DateTime.now().millisecondsSinceEpoch
          }));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Start mileage saved")),
      );
      setState(() {
        endMileageController.clear();
        error = "";
      });
    } else {
      setState(() {
        error = "Please fill in start mileage.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in start mileage.")),
      );
    }
  }

  Future<void> completeMileage() async {
    if (startMileageController.text.isNotEmpty &&
        endMileageController.text.isNotEmpty) {
      try {
        int startMileage = int.parse(startMileageController.text);
        int endMileage = int.parse(endMileageController.text);

        if (endMileage <= startMileage) {
          setState(() {
            error = "End mileage must be greater than start mileage.";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text("End mileage must be greater than start mileage.")),
          );
          return;
        }

        Map<String, dynamic> mileageData = {
          'startMileage': startMileage,
          'endMileage': endMileage,
          'startDate': Timestamp.fromDate(DateTime(
              selectedDate.year, selectedDate.month, selectedDate.day, 12)),
          'endDate': Timestamp.fromDate(selectedDate),
          'uid': _user!.uid,
          'timestamp': Timestamp.now()
        };

        await _db.collection('drivermileage').add(mileageData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mileage entry submitted")),
        );

        // Clear SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('startMileage');

        setState(() {
          startMileageController.clear();
          endMileageController.clear();
          selectedDate = DateTime.now();
          error = "";
        });
        await loadMileages();
      } catch (e) {
        print("Error completing mileage: $e");
        setState(() {
          error = "Failed to complete mileage. Please try again.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to complete mileage. Please try again.")),
        );
      }
    } else {
      setState(() {
        error = "Please enter both start and end mileage.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter both start and end mileage.")),
      );
    }
  }

  void editMileage(Map<String, dynamic> mileage) {
    setState(() {
      editingMileage = mileage;
      startMileageController.text = mileage['startMileage'].toString();
      endMileageController.text = mileage['endMileage'].toString();
      selectedDate = (mileage['startDate'] as Timestamp).toDate();
    });
  }

  Future<void> deleteMileage(String id) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Delete'),
            content:
                Text('Are you sure you want to delete this mileage entry?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text('Delete'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await _db.collection('drivermileage').doc(id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mileage entry deleted successfully")),
        );
        await loadMileages();
      } catch (e) {
        print("Error deleting mileage: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Failed to delete mileage entry. Please try again.")),
        );
      }
    }
  }

  void cancelEdit() {
    setState(() {
      editingMileage = null;
      startMileageController.clear();
      endMileageController.clear();
      selectedDate = DateTime.now();
    });
  }

  String formatDate(Timestamp timestamp) {
    return DateFormat('MM/dd/yyyy').format(timestamp.toDate());
  }

  Map<int, Map<String, List<Map<String, dynamic>>>>
      groupMileagesByYearAndMonth() {
    Map<int, Map<String, List<Map<String, dynamic>>>> grouped = {};
    for (var mileage in mileages) {
      DateTime date = (mileage['startDate'] as Timestamp).toDate();
      int year = date.year;
      String month = DateFormat('MMMM').format(date);
      grouped.putIfAbsent(year, () => {});
      grouped[year]!.putIfAbsent(month, () => []);
      grouped[year]![month]!.add(mileage);
    }
    return grouped;
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
                editingMileage != null ? 'Edit Mileage' : 'Add Mileage',
                style: AppThemes.titleLarge,
              ),
              SizedBox(height: 16),
              TextField(
                controller: startMileageController,
                decoration: AppThemes.inputDecoration
                    .copyWith(labelText: 'Start Mileage'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: saveStartMileage,
                style: AppThemes.elevatedButtonStyle,
                child: Text('Save Start Mileage'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: endMileageController,
                decoration: AppThemes.inputDecoration
                    .copyWith(labelText: 'End Mileage'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                    style: AppThemes.bodyLarge,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2025),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    style: AppThemes.elevatedButtonStyle,
                    child: Text('Select date'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: completeMileage,
                style: AppThemes.elevatedButtonStyle,
                child: Text('Save Daily Mileage'),
              ),
              if (editingMileage != null)
                ElevatedButton(
                  onPressed: cancelEdit,
                  style: AppThemes.elevatedButtonStyle,
                  child: Text('Cancel Edit'),
                ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(error, style: AppThemes.errorText),
                ),
              SwitchListTile(
                title: Text('Show Mileage Entries', style: AppThemes.bodyLarge),
                value: showTransactions,
                onChanged: (bool value) {
                  setState(() {
                    showTransactions = value;
                  });
                },
                activeColor: AppThemes.primaryColor,
              ),
              if (showTransactions) ...[
                Text('Mileage List', style: AppThemes.titleMedium),
                ...groupMileagesByYearAndMonth().entries.map((yearEntry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(yearEntry.key.toString(),
                          style: AppThemes.titleSmall),
                      ...yearEntry.value.entries.map((monthEntry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(monthEntry.key, style: AppThemes.bodyLarge),
                            ...monthEntry.value.map((mileage) {
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    'Date: ${formatDate(mileage['startDate'])}',
                                    style: AppThemes.listTileTitle,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start: ${mileage['startMileage']} miles',
                                        style: AppThemes.bodyMedium,
                                      ),
                                      Text(
                                        'End: ${mileage['endMileage']} miles',
                                        style: AppThemes.bodyMedium,
                                      ),
                                      Text(
                                        'Total: ${mileage['endMileage'] - mileage['startMileage']} miles',
                                        style: AppThemes.listTileAmount,
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: AppThemes.primaryColor),
                                        onPressed: () => editMileage(mileage),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: AppThemes.errorColor),
                                        onPressed: () =>
                                            deleteMileage(mileage['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
