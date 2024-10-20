import 'package:flutter/material.dart';

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
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static final InputDecoration inputDecoration = InputDecoration(
    border: OutlineInputBorder(),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: primaryColor, width: 2.0),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: titleLarge.copyWith(color: Colors.white),
    ),
    textTheme: TextTheme(
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: accentColor,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: titleLarge.copyWith(color: Colors.white),
    ),
    textTheme: TextTheme(
      titleLarge: titleLarge.copyWith(color: Colors.white),
      titleMedium: titleMedium.copyWith(color: Colors.white),
      titleSmall: titleSmall.copyWith(color: Colors.white),
      bodyLarge: bodyLarge.copyWith(color: Colors.white70),
      bodyMedium: bodyMedium.copyWith(color: Colors.white70),
    ),
  );
}
