// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class AppThemes {
  static const Color primaryColor = Colors.blue;
  static const Color accentColor = Colors.purpleAccent;
  static const Color errorColor = Colors.red;

  static final TextStyle titleLarge =
      TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static final TextStyle titleMedium =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static final TextStyle titleSmall =
      TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static final TextStyle bodyLarge = TextStyle(fontSize: 16);
  static final TextStyle bodyMedium = TextStyle(fontSize: 14);
  static final TextStyle listTileTitle = TextStyle(fontWeight: FontWeight.bold);
  static final TextStyle listTileAmount =
      TextStyle(color: primaryColor, fontWeight: FontWeight.bold);
  static final TextStyle errorText = TextStyle(color: errorColor);

  static final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    elevation: 2,
  );

  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: primaryColor, width: 2.0),
      borderRadius: BorderRadius.circular(12),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  static InputDecoration get inputDecoration => InputDecoration(
        filled: true,
        fillColor: Colors.grey[200], // Light background for light theme
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2.0),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: primaryColor,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: titleLarge.copyWith(color: Colors.white),
      foregroundColor: Colors.white,
      surfaceTintColor: primaryColor,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: primaryColor.withOpacity(0.1),
      labelTextStyle: WidgetStateProperty.all(
        bodyMedium.copyWith(fontWeight: FontWeight.bold),
      ),
      iconTheme: WidgetStateProperty.all(
        IconThemeData(color: primaryColor),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
    inputDecorationTheme: inputDecorationTheme,
    textTheme: TextTheme(
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: accentColor,
    brightness: Brightness.dark,
    // Material Design dark background: #121212
    scaffoldBackgroundColor: const Color(0xFF121212),
    // Card theme for elevated surfaces
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E), // Elevated surface color
      elevation: 0,
    ),
    // AppBar with distinct elevation-based color (15% lighter)
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF404040), // Surface color (elevation 1) - 15% lighter
      elevation: 0,
      centerTitle: true,
      titleTextStyle: titleLarge.copyWith(color: Colors.white),
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    // NavigationBar with distinct surface color (elevation 2 - lighter than AppBar, 15% lighter)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF454545), // Lighter surface color for contrast - 15% lighter
      indicatorColor: accentColor.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.all(
        bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white70),
      ),
      iconTheme: WidgetStateProperty.all(
        IconThemeData(color: accentColor),
      ),
    ),
    // Input decoration with distinct background
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E), // Surface color for inputs
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2.0),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
    textTheme: TextTheme(
      titleLarge: titleLarge.copyWith(color: Colors.white),
      titleMedium: titleMedium.copyWith(color: Colors.white),
      titleSmall: titleSmall.copyWith(color: Colors.white),
      bodyLarge: bodyLarge.copyWith(color: Colors.white70),
      bodyMedium: bodyMedium.copyWith(color: Colors.white70),
    ),
  );

  static AppBar buildAppBar(BuildContext context, String title) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: () {
            themeProvider.toggleTheme(isDarkMode);
          },
          tooltip: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
        ),
      ],
    );
  }
}
