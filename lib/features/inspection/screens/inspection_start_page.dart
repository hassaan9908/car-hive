import 'package:flutter/material.dart';
import '../models/inspection_model.dart';
import 'inspection_category_page.dart';

class InspectionStartPage extends StatelessWidget {
  final String carId;
  final String carTitle;
  final String carBrand;
  final String buyerId;
  final String sellerId;

  const InspectionStartPage({
    super.key,
    required this.carId,
    required this.carTitle,
    required this.carBrand,
    required this.buyerId,
    required this.sellerId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Inspection'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Inspect Before You Buy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get a complete evaluation of this vehicle',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Car Title
            Text(
              'Inspecting:',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              carTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 32),

            // What's Included
            Text(
              'What\'s Included',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              colorScheme,
              '🚗',
              'Exterior Inspection',
              'Body condition, paint, lights, windows',
            ),
            _buildFeatureItem(
              colorScheme,
              '🪑',
              'Interior Check',
              'Seats, dashboard, A/C, entertainment',
            ),
            _buildFeatureItem(
              colorScheme,
              '🔧',
              'Engine & Mechanical',
              'Engine, fluids, battery, transmission',
            ),
            _buildFeatureItem(
              colorScheme,
              '🛞',
              'Tires & Suspension',
              'Tread depth, brakes, alignment',
            ),
            _buildFeatureItem(
              colorScheme,
              '📄',
              'Paperwork Review',
              'Registration, service history, insurance',
            ),

            const SizedBox(height: 32),

            // Info Cards
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    colorScheme,
                    isDark,
                    Icons.access_time,
                    '15-20',
                    'Minutes',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    colorScheme,
                    isDark,
                    Icons.checklist_rounded,
                    '27',
                    'Checkpoints',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    colorScheme,
                    isDark,
                    Icons.analytics_outlined,
                    '0-100',
                    'Score',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Start Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _startInspection(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Inspection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Disclaimer
            Text(
              '💡 Tip: This inspection is a guide. For major purchases, always consult a professional mechanic.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    ColorScheme colorScheme,
    String emoji,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    ColorScheme colorScheme,
    bool isDark,
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _startInspection(BuildContext context) {
    // Create new inspection
    final inspection = InspectionModel.createNew(
      carId: carId,
      carTitle: carBrand,
      buyerId: buyerId,
      sellerId: sellerId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionCategoryPage(
          inspection: inspection,
          sellerId: sellerId,
        ),
      ),
    );
  }
}
