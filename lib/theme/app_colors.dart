import 'package:flutter/material.dart';

class AppColors {

  // Primary brand colors (CarHive blue)
  static const Color primaryBlue = Color.fromARGB(255, 43, 128, 207);
  static const Color primaryBlueLight = Color(0xFF3B82F6);
  static const Color primaryBlueDark = Color(0xFF1E40AF);
  
  // Secondary colors
  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color secondaryOrange = Color(0xFFF59E0B);
  static const Color secondaryRed = Color(0xFFEF4444);
  static const Color secondaryPurple = Color(0xFF8B5CF6);
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightOnSurface = Color(0xFF1E293B);
  static const Color lightOnSurfaceVariant = Color(0xFF64748B);
  static const Color lightOutline = Color(0xFFE2E8F0);
  static const Color lightOutlineVariant = Color(0xFFCBD5E1);
  
  // Dark theme colors (matching admin panel)
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  static const Color darkOnSurfaceVariant = Color(0xFFCBD5E1);
  static const Color darkOutline = Color(0xFF475569);
  static const Color darkOutlineVariant = Color(0xFF64748B);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Neutral colors
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueLight],

    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [premiumSilver, chromeSilver],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient performanceGradient = LinearGradient(
    colors: [racingGreen, performanceGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient innovationGradient = LinearGradient(
    colors: [premiumOrange, innovationOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient luxuryGradient = LinearGradient(
    colors: [luxuryPurple, exclusivePurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🌅 Light theme gradients
  static const LinearGradient lightGradient = LinearGradient(
    colors: [lightBackground, lightSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🌙 Dark theme gradients
  static const LinearGradient darkGradient = LinearGradient(
    colors: [darkBackground, darkSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🎨 SPECIAL EFFECTS
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFE2E8F0),
      Color(0xFFCBD5E1),
      Color(0xFFE2E8F0),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  // 🚗 CAR-SPECIFIC COLORS
  static const Color carMetallic = Color(0xFF718096); // Metallic car paint
  static const Color carPearl = Color(0xFFE2E8F0); // Pearl white
  static const Color carMatte = Color(0xFF4A5568); // Matte black
  static const Color carChrome = Color(0xFFCBD5E1); // Chrome finish
}
