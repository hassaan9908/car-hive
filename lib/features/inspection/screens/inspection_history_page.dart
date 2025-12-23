import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import '../models/inspection_model.dart';
import '../services/inspection_service.dart';
import '../services/share_service.dart';
import 'inspection_result_page.dart';

class InspectionHistoryPage extends StatefulWidget {
  const InspectionHistoryPage({super.key});

  @override
  State<InspectionHistoryPage> createState() => _InspectionHistoryPageState();
}

class _InspectionHistoryPageState extends State<InspectionHistoryPage> {
  final InspectionService _inspectionService = InspectionService();
  final ShareService _shareService = ShareService();
  late Future<List<InspectionModel>> _inspectionsFuture;

  @override
  void initState() {
    super.initState();
    _inspectionsFuture = _inspectionService.getUserInspections();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      body: FutureBuilder<List<InspectionModel>>(
        future: _inspectionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading inspections',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final inspections = snapshot.data ?? [];

          if (inspections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No inspections yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your completed inspections will appear here',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: inspections.length,
            itemBuilder: (context, index) =>
                _buildInspectionCard(context, inspections[index], colorScheme),
          );
        },
      ),
    );
  }

  Widget _buildInspectionCard(
    BuildContext context,
    InspectionModel inspection,
    ColorScheme colorScheme,
  ) {
    final score = inspection.overallScore;
    final scoreColor = _getScoreColor(score);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return GestureDetector(
      onTap: () => _openInspection(context, inspection),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inspection.carTitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dateFormat.format(inspection.updatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              score.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                            Text(
                              '/100',
                              style: TextStyle(
                                fontSize: 10,
                                color: scoreColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.fact_check,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${inspection.completedItems}/${inspection.totalItems} items',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(inspection.progress * 100).toStringAsFixed(0)}% complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _openInspection(context, inspection),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View'),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _shareInspection(context, inspection),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteInspection(context, inspection),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openInspection(BuildContext context, InspectionModel inspection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionResultPage(
          inspection: inspection,
          sellerId: inspection.sellerId,
        ),
      ),
    );
  }

  void _shareInspection(BuildContext context, InspectionModel inspection) {
    _shareService.shareInspectionReport(
      inspection,
      onLoading: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      onSuccess: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      },
      onError: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _deleteInspection(BuildContext context, InspectionModel inspection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inspection?'),
        content: Text(
          'Are you sure you want to delete the inspection for ${inspection.carTitle}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (inspection.id != null) {
                  await _inspectionService.deleteInspection(inspection.id!);
                  if (mounted) {
                    setState(() {
                      _inspectionsFuture =
                          _inspectionService.getUserInspections();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Inspection deleted'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting inspection: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.lightGreen;
    if (score >= 50) return Colors.orange;
    if (score >= 30) return Colors.deepOrange;
    return Colors.red;
  }
}
