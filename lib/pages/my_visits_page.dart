import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/visit_models.dart';
import '../services/visit_service.dart';
import '../theme/app_colors.dart';

class MyVisitsPage extends StatefulWidget {
  const MyVisitsPage({super.key});

  @override
  State<MyVisitsPage> createState() => _MyVisitsPageState();
}

class _MyVisitsPageState extends State<MyVisitsPage> {
  final VisitService _visitService = VisitService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('My Visits'),
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Booked'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: user == null
            ? _buildState(
                context,
                icon: Icons.lock_outline,
                title: 'Please sign in',
                subtitle: 'You need an account to view your booked visits.',
              )
            : StreamBuilder<List<VisitBooking>>(
                stream: _visitService.watchUserVisits(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _buildState(
                      context,
                      icon: Icons.error_outline,
                      title: 'Could not load visits',
                      subtitle: snapshot.error.toString(),
                    );
                  }

                  final visits = snapshot.data ?? <VisitBooking>[];
                  final booked =
                      visits.where((visit) => visit.isUpcoming).toList()
                        ..sort((a, b) {
                          final aDate = a.date ??
                              a.createdAt ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          final bDate = b.date ??
                              b.createdAt ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          return aDate.compareTo(bDate);
                        });
                  final completed =
                      visits.where((visit) => visit.isCompleted).toList()
                        ..sort((a, b) {
                          final aDate = a.date ??
                              a.createdAt ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          final bDate = b.date ??
                              b.createdAt ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          return bDate.compareTo(aDate);
                        });

                  return TabBarView(
                    children: [
                      _buildVisitList(
                        context,
                        visits: booked,
                        emptyTitle: 'No booked visits',
                        emptySubtitle:
                            'Your upcoming CarHive assistance visits will show up here.',
                      ),
                      _buildVisitList(
                        context,
                        visits: completed,
                        emptyTitle: 'No completed visits',
                        emptySubtitle:
                            'Completed and past visits will appear here.',
                        allowReschedule: false,
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildVisitList(
    BuildContext context, {
    required List<VisitBooking> visits,
    required String emptyTitle,
    required String emptySubtitle,
    bool allowReschedule = true,
  }) {
    if (visits.isEmpty) {
      return _buildState(
        context,
        icon: Icons.event_note_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: visits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final visit = visits[index];
        return _VisitCard(
          visit: visit,
          allowReschedule: allowReschedule,
          onRequestReschedule: allowReschedule
              ? () => _openRescheduleSheet(context, visit)
              : null,
        );
      },
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

  Future<void> _openRescheduleSheet(
      BuildContext context, VisitBooking visit) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _RescheduleSheet(
          visit: visit,
          visitService: _visitService,
        );
      },
    );
  }
}

class _VisitCard extends StatelessWidget {
  final VisitBooking visit;
  final bool allowReschedule;
  final VoidCallback? onRequestReschedule;

  const _VisitCard({
    required this.visit,
    required this.allowReschedule,
    required this.onRequestReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor =
        visit.isCompleted ? colorScheme.secondary : colorScheme.primary;

    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VisitImage(imageUrl: visit.carImageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.displayTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Badge(
                            label: visit.displayStatus,
                            color: statusColor,
                          ),
                          if (visit.rescheduleStatus == 'pending')
                            _Badge(
                              label: 'Reschedule Pending',
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _VisitLine(
              icon: Icons.calendar_today_outlined,
              text: '${visit.formattedDateLabel} at ${visit.timeSlot}',
            ),
            const SizedBox(height: 8),
            _VisitLine(
              icon: Icons.place_outlined,
              text: visit.locationLabel,
            ),
            const SizedBox(height: 8),
            _VisitLine(
              icon: Icons.credit_card_outlined,
              text:
                  '${visit.paymentMethod} • PKR ${visit.amount.toStringAsFixed(0)}',
            ),
            if (visit.rescheduleStatus != 'none') ...[
              const SizedBox(height: 12),
              _RescheduleStatusBanner(visit: visit),
            ],
            if (allowReschedule) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.greenAction,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    disabledForegroundColor: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.65),
                  ),
                  onPressed: visit.rescheduleStatus == 'pending'
                      ? null
                      : onRequestReschedule,
                  child: Text(
                    visit.rescheduleStatus == 'pending'
                        ? 'Reschedule Requested'
                        : 'Request Reschedule',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VisitImage extends StatelessWidget {
  final String? imageUrl;

  const _VisitImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 92,
      height: 76,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.trim().isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.directions_car_outlined,
                color: theme.colorScheme.primary,
              ),
            )
          : Icon(
              Icons.directions_car_outlined,
              color: theme.colorScheme.primary,
            ),
    );
  }
}

class _VisitLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _VisitLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({
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

class _RescheduleStatusBanner extends StatelessWidget {
  final VisitBooking visit;

  const _RescheduleStatusBanner({required this.visit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requestedDate = visit.requestedRescheduleDate == null
        ? null
        : DateFormat('dd MMM yyyy').format(visit.requestedRescheduleDate!);

    late final Color color;
    late final String message;

    switch (visit.rescheduleStatus) {
      case 'pending':
        color = Colors.orange;
        message =
            'Requested ${requestedDate ?? visit.requestedRescheduleDateKey ?? '--'} at ${visit.requestedRescheduleTimeSlot ?? '--'}.';
        break;
      case 'accepted':
        color = theme.colorScheme.primary;
        message = 'Latest reschedule request was accepted.';
        break;
      case 'rejected':
        color = theme.colorScheme.error;
        message =
            'Latest reschedule request was rejected. Your original booking is unchanged.';
        break;
      default:
        color = theme.colorScheme.primary;
        message = '';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(color: color),
      ),
    );
  }
}

class _RescheduleSheet extends StatefulWidget {
  final VisitBooking visit;
  final VisitService visitService;

  const _RescheduleSheet({
    required this.visit,
    required this.visitService,
  });

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  String? _selectedDateKey;
  String? _selectedTimeSlot;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: FutureBuilder<VisitSchedule?>(
          future: widget.visitService.getScheduleForCity(widget.visit.city),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return _SheetMessage(
                title: 'Could not load schedule',
                subtitle: snapshot.error.toString(),
              );
            }

            final schedule = snapshot.data;
            if (schedule == null) {
              return const _SheetMessage(
                title: 'No schedule available',
                subtitle: 'This city does not have an active admin schedule.',
              );
            }

            final days = schedule.sortedDays.where((day) {
              final sameDate = day.dateKey == widget.visit.dateKey;
              final enabledSlots = day.enabledTimeSlots.isNotEmpty;
              if (sameDate) {
                return day.isAvailable && enabledSlots;
              }
              return day.isSelectable;
            }).toList();

            if (days.isEmpty) {
              return const _SheetMessage(
                title: 'No dates available',
                subtitle: 'There are no open dates to request right now.',
              );
            }

            final selectedDay = days.firstWhere(
              (day) => day.dateKey == (_selectedDateKey ?? days.first.dateKey),
              orElse: () => days.first,
            );
            _selectedDateKey ??= selectedDay.dateKey;
            final enabledSlots = selectedDay.enabledTimeSlots;
            _selectedTimeSlot ??= enabledSlots.contains(widget.visit.timeSlot)
                ? widget.visit.timeSlot
                : null;
            if (_selectedTimeSlot != null &&
                !enabledSlots.contains(_selectedTimeSlot)) {
              _selectedTimeSlot = null;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request Reschedule',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Current booking: ${widget.visit.formattedDateLabel} at ${widget.visit.timeSlot}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose a new date',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: days
                      .map(
                        (day) => ChoiceChip(
                          label: Text(
                            '${DateFormat('dd MMM').format(day.date)}\n${day.availableSeats} seats',
                            textAlign: TextAlign.center,
                          ),
                          selected: _selectedDateKey == day.dateKey,
                          onSelected: (_) {
                            setState(() {
                              _selectedDateKey = day.dateKey;
                              _selectedTimeSlot = null;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose a time slot',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: enabledSlots
                      .map(
                        (slot) => ChoiceChip(
                          label: Text(slot),
                          selected: _selectedTimeSlot == slot,
                          onSelected: (_) {
                            setState(() {
                              _selectedTimeSlot = slot;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting || _selectedTimeSlot == null
                        ? null
                        : () => _submitRequest(selectedDay),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit Request'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitRequest(VisitScheduleDay day) async {
    if (_selectedTimeSlot == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.visitService.requestReschedule(
        visit: widget.visit,
        requestedDate: day.date,
        requestedTimeSlot: _selectedTimeSlot!,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reschedule request submitted.'),
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
          _isSubmitting = false;
        });
      }
    }
  }
}

class _SheetMessage extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SheetMessage({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
