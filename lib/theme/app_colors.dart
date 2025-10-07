import 'package:flutter/material.dart';

class AppColors {
  // 🚗 AUTOMOTIVE-INSPIRED PRIMARY COLORS
  // Deep automotive blue - conveys trust, reliability, and premium quality
  static const Color automotiveBlue = Color(0xFF1A365D); // Deep, rich blue
  static const Color automotiveBlueLight =
      Color(0xFF2D5A87); // Lighter automotive blue
  static const Color automotiveBlueDark =
      Color(0xFF0F2438); // Darker automotive blue

  // Premium silver/chrome - represents luxury and sophistication
  static const Color premiumSilver = Color(0xFF4A5568); // Sophisticated silver
  static const Color chromeSilver = Color(0xFF718096); // Chrome-like silver
  static const Color brushedSilver = Color(0xFFA0AEC0); // Brushed metal silver

  // 🎨 SECONDARY AUTOMOTIVE COLORS
  // Racing green - performance and eco-friendly
  static const Color racingGreen = Color(0xFF2D7D32); // Deep racing green
  static const Color performanceGreen =
      Color(0xFF4CAF50); // Bright performance green

  // Premium orange - energy and innovation
  static const Color premiumOrange =
      Color(0xFFE65100); // Deep automotive orange
  static const Color innovationOrange =
      Color(0xFFFF6B35); // Bright innovation orange

  // Trust red - safety and reliability
  static const Color trustRed = Color(0xFFC62828); // Deep trust red
  static const Color safetyRed = Color(0xFFE53E3E); // Bright safety red

  // Luxury purple - premium and exclusivity
  static const Color luxuryPurple = Color(0xFF6B46C1); // Deep luxury purple
  static const Color exclusivePurple =
      Color(0xFF8B5CF6); // Bright exclusive purple

  // 🌅 LIGHT THEME - Clean, modern automotive showroom
  static const Color lightBackground =
      Color(0xFFF7FAFC); // Clean white with subtle warmth
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white
  static const Color lightSurfaceVariant =
      Color(0xFFF1F5F9); // Subtle gray-white
  static const Color lightSurfaceContainer =
      Color(0xFFE2E8F0); // Container background
  static const Color lightSurfaceContainerHighest =
      Color(0xFFCBD5E1); // Highest container
  static const Color lightOnSurface =
      Color(0xFF1A202C); // Deep charcoal for text
  static const Color lightOnSurfaceVariant =
      Color(0xFF4A5568); // Medium gray for secondary text
  static const Color lightOutline = Color(0xFFE2E8F0); // Subtle borders
  static const Color lightOutlineVariant = Color(0xFFCBD5E1); // Lighter borders

  // 🌙 DARK THEME - Premium automotive interior
  static const Color darkBackground =
      Color(0xFF0D1117); // Deep automotive black
  static const Color darkSurface = Color(0xFF161B22); // Dark surface
  static const Color darkSurfaceVariant =
      Color(0xFF21262D); // Darker surface variant
  static const Color darkSurfaceContainer =
      Color(0xFF30363D); // Container background
  static const Color darkSurfaceContainerHighest =
      Color(0xFF484F58); // Highest container
  static const Color darkOnSurface = Color(0xFFF0F6FC); // Light text
  static const Color darkOnSurfaceVariant =
      Color(0xFF8B949E); // Medium light text
  static const Color darkOutline = Color(0xFF30363D); // Dark borders
  static const Color darkOutlineVariant =
      Color(0xFF484F58); // Lighter dark borders

  // 🚦 STATUS COLORS - Automotive-inspired
  static const Color success = Color(0xFF2D7D32); // Racing green
  static const Color warning = Color(0xFFE65100); // Premium orange
  static const Color error = Color(0xFFC62828); // Trust red
  static const Color info = Color(0xFF2D5A87); // Automotive blue light

  // 🎯 TRUST BADGE COLORS
  static const Color bronzeBadge = Color(0xFF8B4513); // Rich bronze
  static const Color silverBadge = Color(0xFFC0C0C0); // Pure silver
  static const Color goldBadge = Color(0xFFFFD700); // Premium gold

  // 🎨 NEUTRAL PALETTE - Automotive grays
  static const Color neutral50 = Color(0xFFF7FAFC); // Lightest
  static const Color neutral100 = Color(0xFFEDF2F7); // Very light
  static const Color neutral200 = Color(0xFFE2E8F0); // Light
  static const Color neutral300 = Color(0xFFCBD5E1); // Medium light
  static const Color neutral400 = Color(0xFFA0AEC0); // Medium
  static const Color neutral500 = Color(0xFF718096); // Medium dark
  static const Color neutral600 = Color(0xFF4A5568); // Dark
  static const Color neutral700 = Color(0xFF2D3748); // Very dark
  static const Color neutral800 = Color(0xFF1A202C); // Darker
  static const Color neutral900 = Color(0xFF171923); // Darkest

  // 🌈 GRADIENT COLLECTIONS
  static const LinearGradient automotiveGradient = LinearGradient(
    colors: [automotiveBlue, automotiveBlueLight],
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
