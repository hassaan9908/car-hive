import 'package:flutter/material.dart';
import '../models/inspection_model.dart';
import '../models/inspection_section_model.dart';

class InspectionDetailPage extends StatefulWidget {
  final InspectionModel inspection;
  final InspectionSection section;

  const InspectionDetailPage({
    super.key,
    required this.inspection,
    required this.section,
  });

  @override
  State<InspectionDetailPage> createState() => _InspectionDetailPageState();
}

class _InspectionDetailPageState extends State<InspectionDetailPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.section.items[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Column(
        children: [
          // Progress
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: colorScheme.primary.withValues(alpha: 0.1),
            child: Row(
              children: [
                Text(
                  'Item ${_currentIndex + 1} of ${widget.section.items.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / widget.section.items.length,
                      minHeight: 6,
                      backgroundColor: Colors.white,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Text(
                    item.question,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Rating Options
                  Text(
                    'Select Condition:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildRatingOption(
                    'Excellent',
                    '100',
                    'Perfect condition, no issues',
                    Colors.green,
                    100,
                    item.rating,
                  ),
                  const SizedBox(height: 12),
                  _buildRatingOption(
                    'Good',
                    '80',
                    'Minor wear, fully functional',
                    Colors.lightGreen,
                    80,
                    item.rating,
                  ),
                  const SizedBox(height: 12),
                  _buildRatingOption(
                    'Fair',
                    '60',
                    'Some issues, needs attention',
                    Colors.orange,
                    60,
                    item.rating,
                  ),
                  const SizedBox(height: 12),
                  _buildRatingOption(
                    'Poor',
                    '40',
                    'Significant problems',
                    Colors.deepOrange,
                    40,
                    item.rating,
                  ),
                  const SizedBox(height: 12),
                  _buildRatingOption(
                    'Critical',
                    '0',
                    'Major defects, unsafe',
                    Colors.red,
                    0,
                    item.rating,
                  ),

                  const SizedBox(height: 32),

                  // Notes
                  Text(
                    'Additional Notes (Optional):',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add any observations or details...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.primary.withValues(alpha: 0.05),
                    ),
                    onChanged: (value) {
                      setState(() {
                        item.notes = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),
                  // Photo functionality removed per request
                ],
              ),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousItem,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: item.isCompleted ? _nextItem : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentIndex < widget.section.items.length - 1
                            ? 'Next'
                            : 'Complete Section',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingOption(
    String label,
    String score,
    String description,
    Color color,
    int value,
    int currentRating,
  ) {
    final isSelected = currentRating == value;

    return InkWell(
      onTap: () => _selectRating(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  score,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _selectRating(int rating) {
    setState(() {
      widget.section.items[_currentIndex].rating = rating;
      widget.inspection.updatedAt = DateTime.now();
    });
  }

  // Photo capture dialog removed

  void _previousItem() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _nextItem() {
    if (_currentIndex < widget.section.items.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // Section complete
      Navigator.pop(context, true);
    }
  }
}
