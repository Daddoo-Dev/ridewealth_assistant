import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';

class DeleteAccountButton extends StatelessWidget {
  final VoidCallback? onAccountDeleted;

  const DeleteAccountButton({super.key, this.onAccountDeleted});

  Future<void> _handleExport(BuildContext context) async {
    if (!context.mounted) return;

    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser == null) return;

    try {
      final expenses = await _fetchAllExpensesSupabase(supabaseUser.id);
      final income = await _fetchAllIncomeSupabase(supabaseUser.id);
      final mileage = await _fetchAllMileageSupabase(supabaseUser.id);

      if (!context.mounted) return;
      final exportData = _generateExportData(expenses, income, mileage);
      await _openCsv(context, exportData, 'export_data.csv');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export data: $e')),
      );
    }
  }

  Future<void> _handleMileageExport(BuildContext context) async {
    if (!context.mounted) return;

    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser == null) return;

    try {
      final mileage = await _fetchAllMileageSupabase(supabaseUser.id);
      if (!context.mounted) return;
      final formattedMileage = _formatMileageForExport(mileage);
      await _openCsv(context, formattedMileage, 'mileage_data.csv');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export mileage: $e')),
      );
    }
  }

  // Supabase data fetching methods
  Future<List<Map<String, dynamic>>> _fetchAllExpensesSupabase(String userId) async {
    final response = await Supabase.instance.client
        .from('expenses')
        .select()
        .eq('user_id', userId);
    
    return (response as List).map((doc) => {
      ...doc,
      'date': DateTime.parse(doc['date']),
    }).cast<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> _fetchAllIncomeSupabase(String userId) async {
    final response = await Supabase.instance.client
        .from('income')
        .select()
        .eq('user_id', userId);
    
    return (response as List).map((doc) => {
      ...doc,
      'date': DateTime.parse(doc['date']),
    }).cast<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> _fetchAllMileageSupabase(String userId) async {
    final response = await Supabase.instance.client
        .from('mileage')
        .select()
        .eq('user_id', userId);
    
    return (response as List).map((doc) => {
      ...doc,
      'startDate': DateTime.parse(doc['start_date']),
      'endDate': DateTime.parse(doc['end_date']),
    }).cast<Map<String, dynamic>>().toList();
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: _buildDialogContent(dialogContext),
        );
      },
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Are you sure you want to delete your account? All data will be lost if you proceed. Please export your data before proceeding.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
          ),
          child: const Text('Export All Data', textAlign: TextAlign.center),
          onPressed: () => _handleExport(context),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
          ),
          child: const Text('Export All Mileage Data', textAlign: TextAlign.center),
          onPressed: () => _handleMileageExport(context),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(150, 40),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: const Text('Confirm Delete', textAlign: TextAlign.center),
                onPressed: () async {
                  try {
                    await _deleteAccount(context);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete account: $e')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 40),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: const Text('Cancel', textAlign: TextAlign.center),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;
      final supabaseUser = supabase.auth.currentUser;
      
      if (supabaseUser == null) {
        _showError(context, 'No user found');
        return;
      }

      // Call edge function to delete account (requires service role on server)
      final response = await supabase.functions.invoke('delete_account');
      
      if (response.status != 200) {
        final error = response.data?['error'] ?? 'Unknown error';
        throw Exception(error);
      }

      // Sign out locally
      await supabase.auth.signOut();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account deleted successfully')),
        );
        
        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        
        // Call callback if provided
        onAccountDeleted?.call();
      }
    } catch (e) {
      print('Error deleting account: $e');
      if (context.mounted) {
        _showError(context, 'Failed to delete account: $e');
      }
    }
  }

  List<List<dynamic>> _generateExportData(
    List<Map<String, dynamic>> expenses,
    List<Map<String, dynamic>> income,
    List<Map<String, dynamic>> mileage,
  ) {
    final csvData = <List<dynamic>>[];
    
    // Add headers
    csvData.add(['Type', 'Date', 'Amount', 'Description', 'Category']);
    
    // Add expenses
    for (final expense in expenses) {
      csvData.add([
        'Expense',
        expense['date']?.toString() ?? '',
        expense['amount']?.toString() ?? '',
        expense['description'] ?? '',
        expense['category'] ?? '',
      ]);
    }
    
    // Add income
    for (final incomeItem in income) {
      csvData.add([
        'Income',
        incomeItem['date']?.toString() ?? '',
        incomeItem['amount']?.toString() ?? '',
        incomeItem['description'] ?? '',
        incomeItem['category'] ?? '',
      ]);
    }
    
    return csvData;
  }

  List<List<dynamic>> _formatMileageForExport(List<Map<String, dynamic>> mileage) {
    final csvData = <List<dynamic>>[];
    
    // Add headers
    csvData.add(['Start Date', 'End Date', 'Miles', 'Purpose', 'Notes']);
    
    // Add mileage data
    for (final mileageItem in mileage) {
      csvData.add([
        mileageItem['startDate']?.toString() ?? '',
        mileageItem['endDate']?.toString() ?? '',
        mileageItem['miles']?.toString() ?? '',
        mileageItem['purpose'] ?? '',
        mileageItem['notes'] ?? '',
      ]);
    }
    
    return csvData;
  }

  Future<void> _openCsv(BuildContext context, List<List<dynamic>> data, String filename) async {
    final csvString = const ListToCsvConverter().convert(data);

    if (kIsWeb) {
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csvString);
      
      if (context.mounted) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Export Data',
          ),
        );
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16),
        ),
        onPressed: () => _showDeleteConfirmationDialog(context),
        child: const Text('Delete Account'),
      ),
    );
  }
}