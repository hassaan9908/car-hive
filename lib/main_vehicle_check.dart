import 'package:flutter/material.dart';
import 'package:carhive/screens/vehicle_check_screen.dart';

/// Standalone entry point for Vehicle Information Checker
/// 
/// This is a minimal example demonstrating how to use the VehicleCheckScreen.
/// You can integrate VehicleCheckScreen into your existing app by importing
/// it and navigating to it from your main app.
void main() {
  runApp(const VehicleCheckApp());
}

/// Main app widget for Vehicle Information Checker
class VehicleCheckApp extends StatelessWidget {
  const VehicleCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Information Checker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const VehicleCheckScreen(),
    );
  }
}


