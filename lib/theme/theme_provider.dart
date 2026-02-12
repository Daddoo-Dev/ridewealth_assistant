import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;

  ThemeProvider() {
    loadThemeMode();
  }

  /// Toggles to the opposite of the current effective brightness.
  void toggleTheme(BuildContext context) {
    final currentBrightness = Theme.of(context).brightness;
    themeMode = currentBrightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    saveThemeMode();
    notifyListeners();
  }

  Future<void> loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode');
    if (mode == null) {
      themeMode = ThemeMode.system;
    } else {
      themeMode = mode == 'light' ? ThemeMode.light : ThemeMode.dark;
    }
    notifyListeners();
  }

  Future<void> saveThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('themeMode', themeMode == ThemeMode.light ? 'light' : 'dark');
  }
}
