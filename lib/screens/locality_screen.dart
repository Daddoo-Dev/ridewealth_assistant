import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localities.dart';
import '../services/user_settings.dart';
import '../theme/theme_provider.dart';

class LocalityScreen extends StatefulWidget {
  const LocalityScreen({super.key, this.onSaved});

  /// Set when this screen is the gate before the main app. The callback
  /// continues into the app. From account settings the screen pops itself.
  final VoidCallback? onSaved;

  @override
  State<LocalityScreen> createState() => _LocalityScreenState();
}

class _LocalityScreenState extends State<LocalityScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedCode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCode = PlatformDispatcher.instance.locale.countryCode;
    if (Localities.byCode(_selectedCode) == null) _selectedCode = null;
    UserSettings.storedCountryCode().then((code) {
      if (!mounted || code == null) return;
      setState(() => _selectedCode = code);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code = _selectedCode;
    if (code == null || _saving) return;
    setState(() => _saving = true);
    await UserSettings.saveCountry(code);
    if (!mounted) return;
    final onSaved = widget.onSaved;
    if (onSaved != null) {
      onSaved();
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final selected = Localities.byCode(_selectedCode);
    final results = Localities.matching(_query);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your country'),
        automaticallyImplyLeading: widget.onSaved == null,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(context),
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Choose the country where you file. This sets the currency name, the symbol, and whether distance is shown in miles or kilometers.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search countries',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final locality = results[index];
                return RadioListTile<String>(
                  value: locality.countryCode,
                  groupValue: _selectedCode,
                  title: Text(locality.countryName),
                  subtitle: Text(
                    '${locality.currencyName} (${locality.symbol})',
                  ),
                  onChanged: (value) => setState(() => _selectedCode = value),
                );
              },
            ),
          ),
          if (selected != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                '${selected.currencyName} (${selected.symbol}). Distance is shown in ${selected.distanceWord}.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selected == null || _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
