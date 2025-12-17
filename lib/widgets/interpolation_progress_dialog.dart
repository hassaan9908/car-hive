import 'package:flutter/material.dart';

/// Dialog showing interpolation progress
class InterpolationProgressDialog extends StatelessWidget {
  final int current;
  final int total;
  final String message;

  const InterpolationProgressDialog({
    super.key,
    required this.current,
    required this.total,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final progress = current / total;
    
    return Dialog(
      backgroundColor: Colors.black87,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            const Icon(
              Icons.image_outlined,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            
            // Title
            const Text(
              'Generating 360° View',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Progress text
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            
            // Percentage
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Frame count
            Text(
              'Frame $current of $total',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show progress dialog
  static void show(BuildContext context, {
    required int current,
    required int total,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InterpolationProgressDialog(
        current: current,
        total: total,
        message: message,
      ),
    );
  }

  /// Update progress dialog
  static void update(BuildContext context, {
    required int current,
    required int total,
    required String message,
  }) {
    Navigator.of(context).pop();
    show(context, current: current, total: total, message: message);
  }

  /// Hide progress dialog
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}


