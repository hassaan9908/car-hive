import 'package:flutter/material.dart';

class AdminThemeTokens {
  const AdminThemeTokens._();

  static Color pageBackground(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : const Color(0xFFF6F8FB);
  }

  static Color pageSurface(BuildContext context) {
    return pageBackground(context);
  }

  static Color pageBorder(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.outlineVariant.withValues(alpha: 0.38)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.7);
  }

  static Color sidebarBackground(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFF5F5F5);
  }

  static Color sidebarBorder(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4);
  }

  static Color sidebarPrimaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color sidebarSecondaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color sidebarHover(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04);
  }

  static Color sidebarActiveBackground(BuildContext context) {
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
  }

  static Color sidebarActiveBorder(BuildContext context) {
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.24);
  }

  static Color sidebarShadow(BuildContext context) {
    return Colors.black.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.08,
    );
  }
}
