import 'package:flutter/material.dart';
import 'app_colors.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,

  useMaterial3: true,

  // Color Scheme - Automotive Dark Theme
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryOrange,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryOrangeDark,
    onPrimaryContainer: AppColors.primaryOrange,
    secondary: AppColors.secondaryGreen,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.secondaryGreen,
    onSecondaryContainer: AppColors.secondaryGreen,
    tertiary: AppColors.secondaryOrange,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.secondaryOrange,
    onTertiaryContainer: AppColors.secondaryOrange,
    background: Color.fromARGB(255, 29, 21, 14), // Custom dark background
    onBackground: AppColors.darkOnSurface,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    surfaceContainerHighest: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutlineVariant,
    error: AppColors.secondaryRed,
    onError: Colors.white,
    errorContainer: AppColors.secondaryRed,
    onErrorContainer: AppColors.secondaryRed,
    shadow: AppColors.neutral900,
    scrim: AppColors.neutral900,
    inverseSurface: AppColors.lightSurface,
    onInverseSurface: AppColors.lightOnSurface,
    inversePrimary: AppColors.primaryOrangeLight,
  ),

  // App Bar Theme - Automotive Dark Style
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF221910), // Same as app background (#221910)
    foregroundColor: Color(0xFFf48c25), // Orange for title and actions
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Color(0xFFf48c25), // Orange #f48c25
      fontSize: 20,
      fontWeight: FontWeight.w600,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    iconTheme: IconThemeData(color: Color(0xFFf48c25)), // Orange #f48c25
    actionsIconTheme: IconThemeData(color: Color(0xFFf48c25)), // Orange #f48c25 for action buttons
    surfaceTintColor: Colors.transparent,
  ),

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
          const BorderSide(color: AppColors.primaryOrange, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.secondaryRed),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(
      color: AppColors.darkOnSurfaceVariant,
      fontSize: 16,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
    floatingLabelStyle: const TextStyle(
      color: AppColors.primaryOrange,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    ),
  ),

  // Elevated Button Theme - Automotive Dark Style
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryOrange, // #f48c25
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: AppColors.primaryOrange.withOpacity(0.3),
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
      foregroundColor: AppColors.primaryOrange,
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
      foregroundColor: AppColors.primaryOrange,
      side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
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
    backgroundColor: Colors.black, // Black in dark mode
    selectedItemColor: AppColors.primaryOrange,
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

  // Floating Action Button Theme - Automotive Dark Style
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryOrange,
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

  // Scaffold Background - Transparent to allow gradient wrapper to show through
  scaffoldBackgroundColor: Colors.transparent,

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
    selectedColor: AppColors.primaryOrange,
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
