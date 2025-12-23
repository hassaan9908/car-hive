import 'package:flutter/material.dart';
import '../models/inspection_model.dart';
import 'inspection_detail_page.dart';
import 'inspection_result_page.dart';

class InspectionCategoryPage extends StatefulWidget {
  final InspectionModel inspection;
  final String sellerId;

  const InspectionCategoryPage({
    super.key,
    required this.inspection,
    required this.sellerId,
  });

  @override
  State<InspectionCategoryPage> createState() => _InspectionCategoryPageState();
}

class _InspectionCategoryPageState extends State<InspectionCategoryPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Categories'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        actions: [
          if (widget.inspection.completedItems > 0)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showProgress(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${widget.inspection.completedItems}/${widget.inspection.totalItems}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: widget.inspection.progress,
                    minHeight: 10,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(widget.inspection.progress * 100).toStringAsFixed(0)}% Complete',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Categories List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.inspection.sections.length,
              itemBuilder: (context, index) {
                final section = widget.inspection.sections[index];
                return _buildCategoryCard(
                    context, section, colorScheme, isDark);
              },
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.inspection.completedItems > 0
                      ? () => _viewResults(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.inspection.completedItems ==
                            widget.inspection.totalItems
                        ? 'View Final Report'
                        : 'View Progress (${widget.inspection.completedItems}/${widget.inspection.totalItems})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    dynamic section,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final progress = section.progress;
    final isCompleted = section.completedCount == section.totalCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openSection(context, section),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    section.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            section.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor:
                                  colorScheme.primary.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted
                                    ? Colors.green
                                    : colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${section.completedCount}/${section.totalCount}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (section.sectionScore > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Score: ',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            '${section.sectionScore.toStringAsFixed(0)}/100',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(section.sectionScore),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.lightGreen;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  void _openSection(BuildContext context, dynamic section) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionDetailPage(
          inspection: widget.inspection,
          section: section,
        ),
      ),
    );

    if (result == true) {
      setState(() {}); // Refresh to show updates
    }
  }

  void _viewResults(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionResultPage(
          inspection: widget.inspection,
          sellerId: widget.sellerId,
        ),
      ),
    );
  }

  void _showProgress(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inspection Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Items: ${widget.inspection.totalItems}'),
            Text('Completed: ${widget.inspection.completedItems}'),
            Text(
                'Remaining: ${widget.inspection.totalItems - widget.inspection.completedItems}'),
            const SizedBox(height: 16),
            if (widget.inspection.completedItems > 0)
              Text(
                'Current Score: ${widget.inspection.overallScore.toStringAsFixed(0)}/100',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
