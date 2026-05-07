import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/visit_models.dart';
import '../../services/visit_service.dart';

class AdminVisitBookingsPage extends StatefulWidget {
  const AdminVisitBookingsPage({super.key});

  @override
  State<AdminVisitBookingsPage> createState() => _AdminVisitBookingsPageState();
}

class _AdminVisitBookingsPageState extends State<AdminVisitBookingsPage> {
  final VisitService _visitService = VisitService();
  // 'all' | 'upcoming' | 'completed'
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Visit Booking Requests'),
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Upcoming',
                  selected: _filter == 'upcoming',
                  onTap: () => setState(() => _filter = 'upcoming'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Completed',
                  selected: _filter == 'completed',
                  onTap: () => setState(() => _filter = 'completed'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<VisitBooking>>(
        stream: _visitService.watchAllVisits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildEmpty(
              context,
              icon: Icons.error_outline,
              title: 'Could not load bookings',
              subtitle: snapshot.error.toString(),
            );
          }

          final all = snapshot.data ?? <VisitBooking>[];
          final visits = _applyFilter(all);

          if (visits.isEmpty) {
            return _buildEmpty(
              context,
              icon: Icons.event_busy_outlined,
              title: 'No bookings found',
              subtitle: _filter == 'all'
                  ? 'When users book a visit it will appear here.'
                  : 'No $_filter bookings at the moment.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: visits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) =>
                _BookingCard(booking: visits[index], visitService: _visitService),
          );
        },
      ),
    );
  }

  List<VisitBooking> _applyFilter(List<VisitBooking> all) {
    switch (_filter) {
      case 'upcoming':
        return all.where((v) => v.isUpcoming).toList();
      case 'completed':
        return all.where((v) => v.isCompleted).toList();
      default:
        return all;
    }
  }

  Widget _buildEmpty(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final VisitBooking booking;
  final VisitService visitService;

  const _BookingCard({required this.booking, required this.visitService});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    widget.visitService
        .getUserDisplayName(widget.booking.userId)
        .then((name) {
      if (mounted) setState(() => _userName = name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = widget.booking;
    final isUpcoming = booking.isUpcoming;

    final statusColor = isUpcoming
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

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
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.directions_car_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName ?? '...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.displayTitle,
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (booking.createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Requested ${DateFormat('dd MMM yyyy, hh:mm a').format(booking.createdAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _StatusPill(label: booking.displayStatus, color: statusColor),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _Row(label: 'Visit Date', value: booking.formattedDateLabel),
            _Row(label: 'Time Slot', value: booking.timeSlot),
            _Row(label: 'Location', value: booking.locationLabel),
            _Row(label: 'Payment', value: booking.paymentMethod),
            _Row(
              label: 'Amount',
              value: 'PKR ${NumberFormat('#,##0').format(booking.amount)}',
            ),
            if ((booking.engine ?? '').isNotEmpty)
              _Row(label: 'Engine', value: booking.engine!),
            if ((booking.registeredCity ?? '').isNotEmpty)
              _Row(label: 'Reg. City', value: booking.registeredCity!),
            if ((booking.assembly ?? '').isNotEmpty)
              _Row(label: 'Assembly', value: booking.assembly!),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? color : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
