import 'package:flutter/material.dart';

/// Wrapper widget that applies gradient background matching homepage
/// Uses colorScheme.background to colorScheme.surfaceVariant
/// Optimized to prevent glitches during navigation
class GradientScaffoldWrapper extends StatelessWidget {
  final Widget child;

  const GradientScaffoldWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Cache gradient colors to prevent recalculation
    final topColor = colorScheme.surface;
    final bottomColor = colorScheme.surfaceContainerHighest;

    return Container(
      key: const ValueKey('gradient_background'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            topColor,
            bottomColor,
          ],
        ),
      ),
      child: child,
    );
  }
}
