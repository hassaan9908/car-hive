import 'package:flutter/material.dart';

/// Widget that wraps body content with gradient background
/// Prevents glitches by applying gradient directly to body
class GradientBody extends StatelessWidget {
  final Widget child;

  const GradientBody({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest,
          ],
        ),
      ),
      child: child,
    );
  }
}
