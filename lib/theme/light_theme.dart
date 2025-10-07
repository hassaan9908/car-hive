import 'package:flutter/material.dart';
import 'app_colors.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,

  // Color Scheme - Automotive Light Theme
  colorScheme: const ColorScheme.light(
    primary: AppColors.automotiveBlue,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE2E8F0),
    onPrimaryContainer: AppColors.automotiveBlue,
    secondary: AppColors.racingGreen,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE8F5E8),
    onSecondaryContainer: AppColors.racingGreen,
    tertiary: AppColors.premiumOrange,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFF3E0),
    onTertiaryContainer: AppColors.premiumOrange,
    background: AppColors.lightBackground,
    onBackground: AppColors.lightOnSurface,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    onSurfaceVariant: AppColors.lightOnSurfaceVariant,
    surfaceContainer: AppColors.lightSurfaceContainer,
    surfaceContainerHighest: AppColors.lightSurfaceContainerHighest,
    outline: AppColors.lightOutline,
    outlineVariant: AppColors.lightOutlineVariant,
    error: AppColors.trustRed,
    onError: Colors.white,
    errorContainer: Color(0xFFFFEBEE),
    onErrorContainer: AppColors.trustRed,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: AppColors.lightOnSurface,
    onInverseSurface: AppColors.lightSurface,
    inversePrimary: AppColors.automotiveBlueLight,
  ),

  // App Bar Theme - Automotive Style
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.automotiveBlue,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    iconTheme: IconThemeData(color: Colors.white),
    surfaceTintColor: Colors.transparent,
  ),

  // Card Theme
  // cardTheme: CardTheme(
  //   color: Colors.white,
  //   elevation: 1,
  //   shadowColor: const Color(0xFF000000).withOpacity(0.05),
  //   shape: RoundedRectangleBorder(
  //     borderRadius: BorderRadius.circular(16),
  //     side: const BorderSide(
  //       color: Color(0xFFF3F4F6),
  //       width: 1,
  //     ),
  //   ),
  //   margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  // ),

  // Input Decoration Theme - Automotive Style
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurfaceVariant,
    hintStyle: const TextStyle(
      color: AppColors.lightOnSurfaceVariant,
      fontSize: 16,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    prefixIconColor: AppColors.lightOnSurfaceVariant,
    suffixIconColor: AppColors.lightOnSurfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.lightOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.lightOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.automotiveBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.trustRed),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(
      color: AppColors.lightOnSurfaceVariant,
      fontSize: 16,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    floatingLabelStyle: const TextStyle(
      color: AppColors.automotiveBlue,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
  ),

  // Elevated Button Theme - Automotive Style
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.automotiveBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: AppColors.automotiveBlue.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        textBaseline: TextBaseline.alphabetic,
        inherit: false,
      ),
    ),
  ),

  // Text Button Theme - Automotive Style
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.automotiveBlue,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.alphabetic,
        inherit: false,
      ),
    ),
  ),

  // Outlined Button Theme - Automotive Style
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.automotiveBlue,
      side: const BorderSide(color: AppColors.automotiveBlue, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        textBaseline: TextBaseline.alphabetic,
        inherit: false,
      ),
    ),
  ),

  // Bottom Navigation Bar Theme - Automotive Style
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.lightSurface,
    selectedItemColor: AppColors.automotiveBlue,
    unselectedItemColor: AppColors.lightOnSurfaceVariant,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
  ),

  // Tab Bar Theme
  // tabBarTheme: const TabBarTheme(
  //   labelColor: AppColors.primaryBlue,
  //   unselectedLabelColor: Color(0xFF6B7280),
  //   indicatorColor: AppColors.primaryBlue,
  //   indicatorSize: TabBarIndicatorSize.tab,
  //   labelStyle: TextStyle(
  //     fontSize: 16,
  //     fontWeight: FontWeight.w600,
  //   ),
  //   unselectedLabelStyle: TextStyle(
  //     fontSize: 16,
  //     fontWeight: FontWeight.w500,
  //   ),
  // ),

  // Floating Action Button Theme - Automotive Style
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.automotiveBlue,
    foregroundColor: Colors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),

  // Divider Theme - Automotive Style
  dividerTheme: const DividerThemeData(
    color: AppColors.lightOutline,
    thickness: 1,
    space: 1,
  ),

  // Icon Theme - Automotive Style
  iconTheme: const IconThemeData(
    color: AppColors.lightOnSurface,
    size: 24,
  ),

  // Text Theme - Automotive Style
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.lightOnSurface,
      letterSpacing: -0.5,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.lightOnSurface,
      letterSpacing: -0.5,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.lightOnSurface,
      letterSpacing: -0.25,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.lightOnSurface,
      letterSpacing: -0.25,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.lightOnSurface,
      letterSpacing: -0.25,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.lightOnSurface,
      letterSpacing: -0.25,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.lightOnSurface,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.lightOnSurface,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.lightOnSurfaceVariant,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.lightOnSurface,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.lightOnSurface,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.lightOnSurfaceVariant,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.lightOnSurface,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.lightOnSurfaceVariant,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.lightOnSurfaceVariant,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
  ),

  // Scaffold Background - Automotive Style
  scaffoldBackgroundColor: AppColors.lightBackground,

  // List Tile Theme - Automotive Style
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    titleTextStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.lightOnSurface,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    subtitleTextStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.lightOnSurfaceVariant,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
  ),

  // Chip Theme - Automotive Style
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.lightSurfaceVariant,
    selectedColor: AppColors.automotiveBlue,
    disabledColor: AppColors.lightSurfaceVariant,
    labelStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.lightOnSurface,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
);
