import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/visit_models.dart';
import '../../services/visit_service.dart';

class AdminRescheduleRequestsPage extends StatefulWidget {
  const AdminRescheduleRequestsPage({super.key});

  @override
  State<AdminRescheduleRequestsPage> createState() =>
      _AdminRescheduleRequestsPageState();
}

class _AdminRescheduleRequestsPageState
    extends State<AdminRescheduleRequestsPage> {
  final VisitService _visitService = VisitService();
  final Set<String> _busyRequestIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Reschedule Requests'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<AdminRescheduleRequestView>>(
        stream: _visitService.watchPendingRescheduleRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildState(
              context,
              icon: Icons.error_outline,
              title: 'Could not load requests',
              subtitle: snapshot.error.toString(),
            );
          }

          final requests = snapshot.data ?? <AdminRescheduleRequestView>[];
          if (requests.isEmpty) {
            return _buildState(
              context,
              icon: Icons.event_available_outlined,
              title: 'No pending requests',
              subtitle: 'Reschedule requests from users will show up here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = requests[index];
              final visit = item.visit;
              final request = item.request;
              final isBusy = _busyRequestIds.contains(request.id);

              return Card(
                color: theme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.12),
                            child: Icon(
                              Icons.calendar_month_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.userName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  visit?.displayTitle ??
                                      request.carTitle ??
                                      'CarHive Assisted Visit',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Requested ${_formatDateTime(request.requestedDate, request.requestedTimeSlot)}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          _RequestPill(
                            label: '${item.availableSeats} seats left',
                            color: item.availableSeats > 0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DetailLine(
                        label: 'Current booking',
                        value: visit == null
                            ? '${request.currentDateKey ?? '--'} at ${request.currentTimeSlot ?? '--'}'
                            : '${visit.formattedDateLabel} at ${visit.timeSlot}',
                      ),
                      _DetailLine(
                        label: 'Location',
                        value: visit == null
                            ? '${request.area ?? '--'}, ${request.city ?? '--'}'
                            : visit.locationLabel,
                      ),
                      _DetailLine(
                        label: 'Requested slot',
                        value:
                            '${_formatDate(request.requestedDate, request.requestedDateKey)} at ${request.requestedTimeSlot}',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _reviewRequest(
                                        request.id,
                                        accept: false,
                                      ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _reviewRequest(
                                        request.id,
                                        accept: true,
                                      ),
                              child: isBusy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Accept'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date, String? dateKey) {
    if (date != null) {
      return DateFormat('dd MMM yyyy').format(date);
    }
    return dateKey ?? '--';
  }

  String _formatDateTime(DateTime? date, String timeSlot) {
    final dateLabel = _formatDate(date, null);
    return '$dateLabel at $timeSlot';
  }

  Future<void> _reviewRequest(
    String requestId, {
    required bool accept,
  }) async {
    setState(() {
      _busyRequestIds.add(requestId);
    });

    try {
      if (accept) {
        await _visitService.acceptReschedule(requestId);
      } else {
        await _visitService.rejectReschedule(requestId);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Reschedule request accepted.'
                : 'Reschedule request rejected.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyRequestIds.remove(requestId);
        });
      }
    }
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestPill extends StatelessWidget {
  final String label;
  final Color color;

  const _RequestPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
