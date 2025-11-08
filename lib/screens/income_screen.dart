import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';


class IncomeScreen extends StatefulWidget {
  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final supabase = Supabase.instance.client;
  final User? _user = Supabase.instance.client.auth.currentUser;

  List<Map<String, dynamic>> incomes = [];
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  String error = "";
  bool showTransactions = false;
  Map<String, dynamic>? editingIncome;

  final List<String> incomeSources = [
    "Rideshare income",
    "Delivery income",
    "Tips",
    "Bonuses",
    "Other income"
  ];

  @override
  void initState() {
    super.initState();
    loadIncomes();
  }

  Future<void> loadIncomes() async {
    if (_user == null) return;
    final user = _user;
    try {
      final response = await supabase
          .from('income')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: false);
      
      setState(() {
        incomes = (response as List)
            .map((doc) => Map<String, dynamic>.from(doc as Map))
            .toList();
        error = '';
      });
    } catch (e) {
      print("Error loading incomes: $e");
      setState(() {
        error = "Failed to load incomes. Please try again.";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load incomes. Please try again.")),
      );
    }
  }

  Future<void> addIncome() async {
    if (amountController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty) {
      try {
        DateTime localDate = selectedDate;
        localDate =
            DateTime(localDate.year, localDate.month, localDate.day, 12);

        // Validate date is not too far in the future
        if (localDate.isAfter(DateTime.now().add(Duration(days: 1)))) {
          setState(() {
            error = "Date cannot be more than 1 day in the future.";
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Date cannot be more than 1 day in the future.")),
          );
          return;
        }

        double cleanAmount = double.parse(
            amountController.text.replaceAll(RegExp(r'[^0-9.-]'), ''));
        
        // Validate positive amount
        if (cleanAmount <= 0) {
          setState(() {
            error = "Income amount must be greater than zero.";
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Income amount must be greater than zero.")),
          );
          return;
        }
        
        // Validate reasonable income limits
        if (cleanAmount > 100000) {
          setState(() {
            error = "Daily income over \$100,000 seems unreasonable. Please verify.";
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Daily income over \$100,000 seems unreasonable.")),
          );
          return;
        }

        Map<String, dynamic> incomeData = {
          'amount': double.parse(cleanAmount.toStringAsFixed(2)),
          'description': descriptionController.text,
          'date': localDate.toIso8601String(),
          'user_id': _user!.id,
          'notes': notesController.text.isEmpty ? null : notesController.text,
          'created_at': DateTime.now().toIso8601String()
        };

        if (editingIncome != null) {
          await supabase
              .from('income')
              .update(incomeData)
              .eq('id', editingIncome!['id']);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Income updated successfully")),
          );
        } else {
          await supabase.from('income').insert(incomeData);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Income added successfully")),
          );
          setState(() {
            amountController.clear();
            descriptionController.clear();
            notesController.clear();
            selectedDate = DateTime.now();
            editingIncome = null;
            error = '';
          });
          await loadIncomes();
        }
      } catch (e) {
        print("Error adding/updating income: $e");
        setState(() {
          error = "Failed to add/update income. Please try again.";
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to add/update income. Please try again.")),
        );
      }
    } else {
      setState(() {
        error = "Please fill in all fields.";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill in all fields.")),
        );
      }
    }
  }

  void editIncome(Map<String, dynamic> income) {
    setState(() {
      editingIncome = income;
      amountController.text = income['amount'].toString();
      descriptionController.text = income['description'];
      selectedDate = DateTime.parse(income['date']);
    });
  }

  Future<void> deleteIncome(String id) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this income entry?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await supabase.from('income').delete().eq('id', id);
        await loadIncomes();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Income deleted successfully")),
        );
      } catch (e) {
        print("Error deleting income: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete income. Please try again.")),
        );
      }
    }
  }

  void cancelEdit() {
    setState(() {
      editingIncome = null;
      amountController.clear();
      descriptionController.clear();
      notesController.clear();
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
      groupIncomesByYearAndMonth() {
    Map<int, Map<String, List<Map<String, dynamic>>>> grouped = {};
    for (var income in incomes) {
      DateTime date = parseDate(income['date']);
      int year = date.year;
      String month = DateFormat('MMMM').format(date);
      grouped.putIfAbsent(year, () => {});
      grouped[year]!.putIfAbsent(month, () => []);
      grouped[year]![month]!.add(income);
    }
    return grouped;
  }

  List<MapEntry<String, List<Map<String, dynamic>>>> sortMonths(
      Map<String, List<Map<String, dynamic>>> months) {
    final monthOrder = [
      'December',
      'November',
      'October',
      'September',
      'August',
      'July',
      'June',
      'May',
      'April',
      'March',
      'February',
      'January'
    ];
    return months.entries.toList()
      ..sort((a, b) =>
          monthOrder.indexOf(a.key).compareTo(monthOrder.indexOf(b.key)));
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
                editingIncome != null ? 'Edit Income' : 'Add Income',
                style: AppThemes.titleLarge,
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration:
                    AppThemes.inputDecoration.copyWith(labelText: 'Amount'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: AppThemes.inputDecoration
                    .copyWith(labelText: 'Description'),
              ),
              SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: AppThemes.inputDecoration
                    .copyWith(
                      labelText: 'Notes (Optional)',
                      hintText: 'Add additional notes',
                    ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
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
                onPressed: addIncome,
                style: AppThemes.elevatedButtonStyle,
                child: Text(
                    editingIncome != null ? 'Update Income' : 'Add Income'),
              ),
              if (editingIncome != null)
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
                title: Text('Show Transactions', style: AppThemes.bodyLarge),
                value: showTransactions,
                onChanged: (bool value) {
                  setState(() {
                    showTransactions = value;
                  });
                },
                activeColor: AppThemes.primaryColor,
              ),
              if (showTransactions) ...[
                Text('Income List', style: AppThemes.titleMedium),
                ...groupIncomesByYearAndMonth().entries.map((yearEntry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(yearEntry.key.toString(),
                          style: AppThemes.titleSmall),
                      ...sortMonths(yearEntry.value).map((monthEntry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(monthEntry.key, style: AppThemes.bodyLarge),
                            ...(() {
                              final sortedIncomes = List<Map<String, dynamic>>.from(monthEntry.value);
                              sortedIncomes.sort((a, b) => parseDate(b['date']).compareTo(parseDate(a['date'])));
                              return sortedIncomes.map((income) {
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      'Date: ${formatDate(income['date'])}',
                                      style: AppThemes.listTileTitle,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Amount: \$${income['amount'].toStringAsFixed(2)}',
                                          style: AppThemes.listTileAmount,
                                        ),
                                        Text(
                                          'Description: ${income['description']}',
                                          style: AppThemes.bodyMedium,
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, color: AppThemes.primaryColor),
                                          onPressed: () => editIncome(income),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: AppThemes.errorColor),
                                          onPressed: () => deleteIncome(income['id']),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList();
                            })(),
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
