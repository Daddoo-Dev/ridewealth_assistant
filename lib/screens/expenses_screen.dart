import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class ExpensesScreen extends StatefulWidget {
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> expenses = [];
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String category = '';
  String error = "";
  bool showTransactions = false;
  Map<String, dynamic>? editingExpense;

  final List<String> expenseCategories = [
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
    "Other expenses"
  ];

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    if (_user == null) return;
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('expenses')
          .where("uid", isEqualTo: _user.uid)
          .orderBy("date", descending: true)
          .get();
      setState(() {
        expenses = querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    } catch (e) {
      print("Error loading expenses: $e");
      setState(() {
        error = "Failed to load expenses. Please try again.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load expenses. Please try again.")),
      );
    }
  }

  Future<void> addExpense() async {
    if (amountController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        category.isNotEmpty) {
      try {
        DateTime localDate = selectedDate;
        localDate =
            DateTime(localDate.year, localDate.month, localDate.day, 12);

        DateTime utcDate = localDate.toUtc();

        double cleanAmount = double.parse(
            amountController.text.replaceAll(RegExp(r'[^0-9.-]'), ''));

        Map<String, dynamic> expenseData = {
          'amount': double.parse(cleanAmount.toStringAsFixed(2)),
          'description': descriptionController.text,
          'date': Timestamp.fromDate(utcDate),
          'category': category,
          'type': "expense",
          'uid': _user!.uid,
          'timestamp': Timestamp.now()
        };

        if (editingExpense != null) {
          await _db
              .collection('expenses')
              .doc(editingExpense!['id'])
              .update(expenseData);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Expense updated successfully")),
          );
        } else {
          await _db.collection('expenses').add(expenseData);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Expense added successfully")),
          );
        }

        setState(() {
          amountController.clear();
          descriptionController.clear();
          selectedDate = DateTime.now();
          category = '';
          editingExpense = null;
          error = '';
        });
        await loadExpenses();
      } catch (e) {
        print("Error adding/updating expense: $e");
        setState(() {
          error = "Failed to add/update expense. Please try again.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to add/update expense. Please try again.")),
        );
      }
    } else {
      setState(() {
        error = "Please fill in all fields.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields.")),
      );
    }
  }

  void editExpense(Map<String, dynamic> expense) {
    setState(() {
      editingExpense = expense;
      amountController.text = expense['amount'].toString();
      descriptionController.text = expense['description'];
      selectedDate = (expense['date'] as Timestamp).toDate();
      category = expense['category'];
    });
  }

  Future<void> deleteExpense(String id) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this expense entry?"),
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
        await _db.collection('expenses').doc(id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Expense entry deleted successfully")),
        );
        await loadExpenses();
      } catch (e) {
        print("Error deleting expense: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Failed to delete expense entry. Please try again.")),
        );
      }
    }
  }

  void cancelEdit() {
    setState(() {
      editingExpense = null;
      amountController.clear();
      descriptionController.clear();
      selectedDate = DateTime.now();
      category = '';
    });
  }

  String formatDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('MM/dd/yyyy').format(date.toDate().toLocal());
    } else if (date is DateTime) {
      return DateFormat('MM/dd/yyyy').format(date.toLocal());
    } else if (date is String) {
      return date; // Return as is if it's already a formatted string
    }
    return 'Invalid Date';
  }

  DateTime parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate().toLocal();
    } else if (date is DateTime) {
      return date.toLocal();
    } else if (date is String) {
      return DateTime.parse(date).toLocal();
    }
    return DateTime.now(); // Default to current date if parsing fails
  }

  Map<int, Map<String, List<Map<String, dynamic>>>>
      groupExpensesByYearAndMonth() {
    Map<int, Map<String, List<Map<String, dynamic>>>> grouped = {};
    for (var expense in expenses) {
      DateTime date = parseDate(expense['date']);
      int year = date.year;
      String month = DateFormat('MMMM').format(date);
      grouped.putIfAbsent(year, () => {});
      grouped[year]!.putIfAbsent(month, () => []);
      grouped[year]![month]!.add(expense);
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
                editingExpense != null ? 'Edit Expense' : 'Add Expense',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration:
                    AppThemes.inputDecoration.copyWith(labelText: 'Amount'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: AppThemes.inputDecoration
                    .copyWith(labelText: 'Description'),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                    style: Theme.of(context).textTheme.bodyLarge,
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
              DropdownButtonFormField<String>(
                value: category.isEmpty ? null : category,
                decoration:
                    AppThemes.inputDecoration.copyWith(labelText: 'Category'),
                isExpanded: true,
                items: expenseCategories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    category = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: addExpense,
                style: AppThemes.elevatedButtonStyle,
                child: Text(
                    editingExpense != null ? 'Update Expense' : 'Add Expense'),
              ),
              if (editingExpense != null)
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
                title: Text('Show Transactions',
                    style: Theme.of(context).textTheme.bodyLarge),
                value: showTransactions,
                onChanged: (bool value) {
                  setState(() {
                    showTransactions = value;
                  });
                },
                activeColor: AppThemes.primaryColor,
              ),
              if (showTransactions) ...[
                Text('Expense List',
                    style: Theme.of(context).textTheme.titleMedium),
                ...groupExpensesByYearAndMonth().entries.map((yearEntry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(yearEntry.key.toString(),
                          style: Theme.of(context).textTheme.titleSmall),
                      ...sortMonths(yearEntry.value).map((monthEntry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(monthEntry.key,
                                style: Theme.of(context).textTheme.bodyLarge),
                            ...monthEntry.value
                                .sorted((a, b) => parseDate(b['date'])
                                    .compareTo(parseDate(a['date'])))
                                .map((expense) {
                              return ListTile(
                                title: Text(
                                  'Date: ${formatDate(expense['date'])}',
                                  style: AppThemes.listTileTitle,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Amount: \$${expense['amount'].toStringAsFixed(2)}',
                                      style: AppThemes.listTileAmount,
                                    ),
                                    Text(
                                      'Description: ${expense['description']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    Text(
                                      'Category: ${expense['category']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: AppThemes.primaryColor),
                                      onPressed: () => editExpense(expense),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: AppThemes.errorColor),
                                      onPressed: () =>
                                          deleteExpense(expense['id']),
                                    ),
                                  ],
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
