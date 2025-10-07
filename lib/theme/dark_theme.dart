import 'package:flutter/material.dart';
import 'app_colors.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,

  useMaterial3: true,

  // Color Scheme - Automotive Dark Theme
  colorScheme: const ColorScheme.dark(
    primary: AppColors.automotiveBlueLight,
    onPrimary: Colors.white,
    primaryContainer: AppColors.automotiveBlueDark,
    onPrimaryContainer: AppColors.automotiveBlueLight,
    secondary: AppColors.performanceGreen,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.racingGreen,
    onSecondaryContainer: AppColors.performanceGreen,
    tertiary: AppColors.innovationOrange,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.premiumOrange,
    onTertiaryContainer: AppColors.innovationOrange,
    background: AppColors.darkBackground,
    onBackground: AppColors.darkOnSurface,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    surfaceContainer: AppColors.darkSurfaceContainer,
    surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutlineVariant,
    error: AppColors.safetyRed,
    onError: Colors.white,
    errorContainer: AppColors.trustRed,
    onErrorContainer: AppColors.safetyRed,
    shadow: AppColors.neutral900,
    scrim: AppColors.neutral900,
    inverseSurface: AppColors.lightSurface,
    onInverseSurface: AppColors.lightOnSurface,
    inversePrimary: AppColors.automotiveBlueLight,
  ),

  // App Bar Theme - Automotive Dark Style
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.darkOnSurface,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: AppColors.darkOnSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    iconTheme: IconThemeData(color: AppColors.darkOnSurface),
    surfaceTintColor: Colors.transparent,
  ),

  // Card Theme
  // cardTheme: CardTheme(
  //   color: AppColors.darkSurface,
  //   elevation: 4,
  //   shadowColor: AppColors.neutral900,
  //   shape: RoundedRectangleBorder(
  //     borderRadius: BorderRadius.circular(12),
  //   ),
  // ),

  // Input Decoration Theme - Automotive Dark Style
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurfaceVariant,
    hintStyle: const TextStyle(
      color: AppColors.darkOnSurfaceVariant,
      fontSize: 16,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    prefixIconColor: AppColors.darkOnSurfaceVariant,
    suffixIconColor: AppColors.darkOnSurfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.darkOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.darkOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
          const BorderSide(color: AppColors.automotiveBlueLight, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.safetyRed),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(
      color: AppColors.darkOnSurfaceVariant,
      fontSize: 16,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    floatingLabelStyle: const TextStyle(
      color: AppColors.automotiveBlueLight,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
  ),

  // Elevated Button Theme - Automotive Dark Style
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.automotiveBlueLight,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: AppColors.automotiveBlueLight.withValues(alpha: 0.3),
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

  // Text Button Theme - Automotive Dark Style
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.automotiveBlueLight,
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

  // Outlined Button Theme - Automotive Dark Style
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.automotiveBlueLight,
      side: const BorderSide(color: AppColors.automotiveBlueLight, width: 1.5),
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

  // Bottom Navigation Bar Theme - Automotive Dark Style
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: AppColors.automotiveBlueLight,
    unselectedItemColor: AppColors.darkOnSurfaceVariant,
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
  //   labelColor: AppColors.automotiveBlueLight,
  //   unselectedLabelColor: AppColors.darkOnSurfaceVariant,
  //   indicatorColor: AppColors.automotiveBlueLight,
  //   indicatorSize: TabBarIndicatorSize.tab,
  // ),

  // Floating Action Button Theme - Automotive Dark Style
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.automotiveBlueLight,
    foregroundColor: Colors.white,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),

  // Divider Theme - Automotive Dark Style
  dividerTheme: const DividerThemeData(
    color: AppColors.darkOutline,
    thickness: 1,
    space: 1,
  ),

  // Icon Theme - Automotive Dark Style
  iconTheme: const IconThemeData(
    color: AppColors.darkOnSurface,
    size: 24,
  ),

  // Text Theme - Automotive Dark Style
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.darkOnSurface,
      letterSpacing: -0.5,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.darkOnSurface,
      letterSpacing: -0.5,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.darkOnSurface,
      letterSpacing: -0.25,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.darkOnSurface,
      letterSpacing: -0.25,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.darkOnSurface,
      letterSpacing: -0.25,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.darkOnSurface,
      letterSpacing: -0.25,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.darkOnSurface,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.darkOnSurface,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.darkOnSurfaceVariant,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.darkOnSurface,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.darkOnSurface,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.darkOnSurfaceVariant,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.darkOnSurface,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.darkOnSurfaceVariant,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.darkOnSurfaceVariant,
      letterSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
  ),

  // Scaffold Background - Automotive Dark Style
  scaffoldBackgroundColor: AppColors.darkBackground,

  // List Tile Theme - Automotive Dark Style
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    titleTextStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.darkOnSurface,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    subtitleTextStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.darkOnSurfaceVariant,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
  ),

  // Chip Theme - Automotive Dark Style
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.darkSurfaceVariant,
    selectedColor: AppColors.automotiveBlueLight,
    disabledColor: AppColors.darkSurfaceVariant,
    labelStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.darkOnSurface,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
);
