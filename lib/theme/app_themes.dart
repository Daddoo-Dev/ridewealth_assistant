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
      indicatorColor: primaryColor.withValues(alpha: 0.1),
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
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: titleLarge.copyWith(color: Colors.white),
      foregroundColor: Colors.white,
      surfaceTintColor: accentColor,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.grey[900],
      indicatorColor: accentColor.withValues(alpha: 0.1),
      labelTextStyle: WidgetStateProperty.all(
        bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white70),
      ),
      iconTheme: WidgetStateProperty.all(
        IconThemeData(color: accentColor),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
    inputDecorationTheme: inputDecorationTheme,
    textTheme: TextTheme(
      titleLarge: titleLarge.copyWith(color: Colors.white),
      titleMedium: titleMedium.copyWith(color: Colors.white),
      titleSmall: titleSmall.copyWith(color: Colors.white),
      bodyLarge: bodyLarge.copyWith(color: Colors.white70),
      bodyMedium: bodyMedium.copyWith(color: Colors.white70),
    ),
  );
}
