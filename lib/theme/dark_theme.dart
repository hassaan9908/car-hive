import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: Colors.grey.shade400,
    secondary: Colors.grey.shade200,
    surface: const Color.fromARGB(255, 45, 55, 72),
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Colors.grey.shade200,
    outline: Colors.grey.shade600,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color.fromARGB(255, 55, 65, 85),
    hintStyle: TextStyle(color: Colors.grey.shade400),
    prefixIconColor: Colors.grey.shade400,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade600),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade600),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    // Set the text color to white
    labelStyle: const TextStyle(color: Colors.white),
    // For actual input text
    floatingLabelStyle: const TextStyle(color: Colors.white),
    // For input text
    // This is not always respected, so you may need to set style: TextStyle(color: Colors.white) in the TextField itself
  ),
  tabBarTheme: const TabBarThemeData(
    labelStyle: TextStyle(color: Colors.white), // instead of labelColor
    unselectedLabelStyle:
        TextStyle(color: Colors.grey), // instead of unselectedLabelColor
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
);
