import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class MileageScreen extends StatefulWidget {
  @override
  MileageScreenState createState() => MileageScreenState();
}

class MileageScreenState extends State<MileageScreen> {
  final supabase = Supabase.instance.client;
  final User? _user = Supabase.instance.client.auth.currentUser;

  List<Map<String, dynamic>> mileages = [];
  TextEditingController startMileageController = TextEditingController();
  TextEditingController endMileageController = TextEditingController();
  TextEditingController notesController = TextEditingController();
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
    final user = _user;
    try {
      final response = await supabase
          .from('mileage')
          .select()
          .eq('user_id', user.id)
          .order('start_date', ascending: false);
      
      setState(() {
        mileages = (response as List)
            .map((doc) => Map<String, dynamic>.from(doc as Map))
            .toList();
      });
    } catch (e) {
      print("Error loading mileages: $e");
      setState(() {
        error = "Failed to load mileages. Please try again.";
      });
      if (!mounted) return;
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

  Future<void> completeMileage() async {
    if (_user == null) {
      setState(() {
        error = "You must be logged in to submit mileage.";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must be logged in to submit mileage.")),
      );
      return;
    }
    if (startMileageController.text.isEmpty || endMileageController.text.isEmpty) {
      setState(() {
        error = "Both start and end mileage must be entered to submit.";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Both start and end mileage must be entered to submit.")),
      );
      return;
    }
    
    // Validate date is not too far in the future
    if (selectedDate.isAfter(DateTime.now().add(Duration(days: 1)))) {
      setState(() {
        error = "Date cannot be more than 1 day in the future.";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Date cannot be more than 1 day in the future.")),
      );
      return;
    }
    
    int startMileage;
    int endMileage;
    
    try {
      startMileage = int.parse(startMileageController.text);
      endMileage = int.parse(endMileageController.text);
    } catch (e) {
      setState(() {
        error = "Mileage must be valid numbers.";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mileage must be valid numbers.")),
      );
      return;
    }
    
    // Validate positive numbers
    if (startMileage < 0 || endMileage < 0) {
      setState(() {
        error = "Mileage cannot be negative.";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mileage cannot be negative.")),
      );
      return;
    }
    
    // Validate reasonable mileage limits
    if (startMileage > 999999 || endMileage > 999999) {
      setState(() {
        error = "Mileage values are unreasonably high.";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mileage values are unreasonably high.")),
      );
      return;
    }
    
    if (endMileage <= startMileage) {
      setState(() {
        error = "End mileage must be greater than start mileage.";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("End mileage must be greater than start mileage.")),
      );
      return;
    }
    
    // Validate reasonable daily mileage
    int totalMiles = endMileage - startMileage;
    if (totalMiles > 1000) {
      setState(() {
        error = "Daily mileage over 1000 miles/km seems unreasonable. Please verify.";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Daily mileage over 1000 miles/km seems unreasonable.")),
      );
      return;
    }
    Map<String, dynamic> mileageData = {
      'start_mileage': startMileage,
      'end_mileage': endMileage,
      'start_date': selectedDate.toIso8601String(),
      'end_date': selectedDate.toIso8601String(),
      'user_id': _user.id,
      'notes': notesController.text.isEmpty ? null : notesController.text,
      'created_at': DateTime.now().toIso8601String()
    };
    try {
      await supabase.from('mileage').insert(mileageData);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('startMileage');
      setState(() {
        startMileageController.clear();
        endMileageController.clear();
        notesController.clear();
        selectedDate = DateTime.now();
        error = '';
      });
      await loadMileages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mileage submitted successfully")),
      );
    } catch (e) {
      print("Error submitting mileage: $e");
      setState(() {
        error = "Failed to submit mileage. Please try again.";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit mileage. Please try again.")),
      );
    }
  }

  Future<void> saveStartMileage() async {
    if (startMileageController.text.isEmpty) {
      setState(() {
        error = "Please enter your start mileage to save.";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter your start mileage to save.")),
      );
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> startMileageData = {
      'mileage': int.parse(startMileageController.text),
      'date': selectedDate.toIso8601String(),
    };
    await prefs.setString('startMileage', jsonEncode(startMileageData));
    setState(() {
      error = '';
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Start Mileage Saved")),
    );
  }

  void editMileage(Map<String, dynamic> mileage) {
    setState(() {
      editingMileage = mileage;
      startMileageController.text = mileage['start_mileage'].toString();
      endMileageController.text = mileage['end_mileage'].toString();
      selectedDate = DateTime.parse(mileage['start_date']);
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
        await supabase.from('mileage').delete().eq('id', id);
        if (!mounted) return;
        await loadMileages();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mileage deleted successfully")),
        );
      } catch (e) {
        print("Error deleting mileage: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete mileage. Please try again.")),
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

  String formatDate(dynamic date) {
    if (date is DateTime) {
      return DateFormat('MM/dd/yyyy').format(date.toLocal());
    } else if (date is String) {
      return DateFormat('MM/dd/yyyy').format(DateTime.parse(date).toLocal());
    }
    return 'Invalid Date';
  }

  DateTime parseDate(dynamic date) {
    if (date is DateTime) {
      return date.toLocal();
    } else if (date is String) {
      return DateTime.parse(date).toLocal();
    }
    return DateTime.now(); // Default to current date if parsing fails
  }

  Map<int, Map<String, List<Map<String, dynamic>>>>
      groupMileagesByYearAndMonth() {
    Map<int, Map<String, List<Map<String, dynamic>>>> grouped = {};
    for (var mileage in mileages) {
      DateTime date = DateTime.parse(mileage['start_date']);
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
                decoration: AppThemes.getInputDecoration(context)
                    .copyWith(labelText: 'Start Mileage'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: saveStartMileage,
                style: AppThemes.elevatedButtonStyle,
                child: Text('Save Mileage'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: endMileageController,
                decoration: AppThemes.getInputDecoration(context)
                    .copyWith(labelText: 'End Mileage'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: AppThemes.getInputDecoration(context)
                    .copyWith(
                      labelText: 'Notes (Optional)',
                      hintText: 'Add notes about this trip',
                    ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: completeMileage,
                style: AppThemes.elevatedButtonStyle,
                child: Text('Submit Mileage'),
              ),
              SizedBox(height: 12),
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
                                    'Date: ${formatDate(mileage['start_date'])}',
                                    style: AppThemes.listTileTitle,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start: ${mileage['start_mileage']} miles/km',
                                        style: AppThemes.bodyMedium,
                                      ),
                                      Text(
                                        'End: ${mileage['end_mileage']} miles/km',
                                        style: AppThemes.bodyMedium,
                                      ),
                                      Text(
                                        'Total: ${mileage['end_mileage'] - mileage['start_mileage']} miles/km',
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
