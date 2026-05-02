// ignore: file_names
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'checkout.dart';
import '../models/visit_models.dart';
import '../services/visit_service.dart';

class BookVisitScreen extends StatefulWidget {
  final String carModel;
  final String carYear;
  final String engine;
  final String registeredCity;
  final String assembly;
  final String? carAdId;
  final String? carImageUrl;

  const BookVisitScreen({
    super.key,
    required this.carModel,
    required this.carYear,
    required this.engine,
    required this.registeredCity,
    required this.assembly,
    this.carAdId,
    this.carImageUrl,
  });

  @override
  State<BookVisitScreen> createState() => _BookVisitScreenState();
}

class _BookVisitScreenState extends State<BookVisitScreen> {
  final VisitService _visitService = VisitService();

  String? selectedCity;
  String? selectedArea;
  String? selectedDateKey;
  String? selectedSlot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Book Visit'),
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.dividerColor),
        ),
      ),
      body: StreamBuilder<List<VisitSchedule>>(
        stream: _visitService.watchSchedules(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildMessageState(
              context,
              icon: Icons.error_outline,
              title: 'Could not load visit schedule',
              subtitle: snapshot.error.toString(),
            );
          }

          final schedules = snapshot.data ?? <VisitSchedule>[];
          if (schedules.isEmpty) {
            return _buildMessageState(
              context,
              icon: Icons.event_busy_outlined,
              title: 'Visit booking is unavailable',
              subtitle:
                  'The admin team has not published any visit schedules yet.',
            );
          }

          _syncSelection(schedules);

          final selectedSchedule = schedules.firstWhere(
            (schedule) => schedule.city == selectedCity,
            orElse: () => schedules.first,
          );
          final selectedDay = selectedDateKey == null
              ? null
              : selectedSchedule.days[selectedDateKey];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStepCircle('1', 'Info', completed: true),
                    _buildStepConnector(context),
                    _buildStepCircle('2', 'Visit', active: true),
                    _buildStepConnector(context),
                    _buildStepCircle('3', 'Checkout'),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  context,
                  icon: Icons.event_available_outlined,
                  title: 'Visit Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCity,
                        decoration: const InputDecoration(
                          labelText: 'Select City',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                        items: schedules
                            .map(
                              (schedule) => DropdownMenuItem<String>(
                                value: schedule.city,
                                child: Text(schedule.city),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCity = value;
                            selectedArea = null;
                            selectedDateKey = null;
                            selectedSlot = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedArea,
                        decoration: const InputDecoration(
                          labelText: 'Select Area',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                        items: selectedSchedule.areas
                            .map(
                              (area) => DropdownMenuItem<String>(
                                value: area,
                                child: Text(area),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedArea = value;
                            selectedDateKey = null;
                            selectedSlot = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (selectedArea != null) ...[
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'Available Dates',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedSchedule.sortedDays.isEmpty)
                          Text(
                            'No dates available for this city right now.',
                            style: theme.textTheme.bodyMedium,
                          )
                        else
                          _buildDateGrid(
                            context,
                            selectedSchedule.sortedDays,
                          ),
                        if (selectedDay != null) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Available Time Slots',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (selectedDay.enabledTimeSlots.isEmpty)
                            Text(
                              'No enabled time slots on this date.',
                              style: theme.textTheme.bodyMedium,
                            )
                          else
                            _buildSlotGrid(
                              context,
                              selectedDay.enabledTimeSlots,
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canContinue && selectedDay != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutScreen(
                                  carModel: widget.carModel,
                                  carYear: widget.carYear,
                                  engine: widget.engine,
                                  registeredCity: widget.registeredCity,
                                  assembly: widget.assembly,
                                  selectedCity: selectedCity!,
                                  selectedArea: selectedArea!,
                                  selectedDate: selectedDay.date,
                                  selectedTimeSlot: selectedSlot!,
                                  carAdId: widget.carAdId,
                                  carImageUrl: widget.carImageUrl,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Continue to Checkout'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool get _canContinue {
    return selectedCity != null &&
        selectedArea != null &&
        selectedDateKey != null &&
        selectedSlot != null;
  }

  void _syncSelection(List<VisitSchedule> schedules) {
    if (schedules.isEmpty) {
      return;
    }

    selectedCity ??= schedules.first.city;
    if (!schedules.any((schedule) => schedule.city == selectedCity)) {
      selectedCity = schedules.first.city;
      selectedArea = null;
      selectedDateKey = null;
      selectedSlot = null;
    }

    final schedule = schedules.firstWhere(
      (item) => item.city == selectedCity,
      orElse: () => schedules.first,
    );

    if (selectedArea == null && schedule.areas.isNotEmpty) {
      selectedArea = schedule.areas.first;
    }
    if (selectedArea != null && !schedule.areas.contains(selectedArea)) {
      selectedArea = schedule.areas.isEmpty ? null : schedule.areas.first;
      selectedDateKey = null;
      selectedSlot = null;
    }
    if (selectedDateKey != null &&
        !schedule.days.containsKey(selectedDateKey)) {
      selectedDateKey = null;
      selectedSlot = null;
    }
    final selectedDay =
        selectedDateKey == null ? null : schedule.days[selectedDateKey];
    if (selectedDay != null &&
        !selectedDay.enabledTimeSlots.contains(selectedSlot)) {
      selectedSlot = null;
    }
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDateTile(BuildContext context, VisitScheduleDay day) {
    final theme = Theme.of(context);
    final selected = selectedDateKey == day.dateKey;
    final enabled = day.isSelectable;
    final colorScheme = theme.colorScheme;
    final orange = colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: !enabled
          ? null
          : () {
              setState(() {
                selectedDateKey = day.dateKey;
                selectedSlot = null;
              });
            },
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: 122,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                selected ? orange.withValues(alpha: 0.12) : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? orange : theme.dividerColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEE').format(day.date),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? orange : theme.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                DateFormat('dd MMM').format(day.date),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                day.statusLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: !day.isAvailable
                      ? theme.colorScheme.error
                      : day.isFull
                          ? Colors.orange
                          : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotTile(BuildContext context, String slot) {
    final theme = Theme.of(context);
    final selected = selectedSlot == slot;
    final colorScheme = theme.colorScheme;
    final orange = colorScheme.primary;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            selectedSlot = slot;
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selected ? orange.withValues(alpha: 0.12) : colorScheme.surface,
          foregroundColor:
              selected ? orange : theme.textTheme.bodyMedium?.color,
          side: BorderSide(
            color: selected ? orange : theme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(
          slot,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: selected ? orange : theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStepCircle(
    String number,
    String label, {
    bool active = false,
    bool completed = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUpcoming = !completed && !active;
    final circleColor = isUpcoming
        ? theme.disabledColor.withValues(alpha: 0.22)
        : colorScheme.primary;
    final numberColor =
        isUpcoming ? theme.textTheme.bodyMedium?.color : Colors.white;
    final labelColor = active || completed
        ? colorScheme.primary
        : theme.textTheme.bodyMedium?.color;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: completed
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : Text(
                  number,
                  style: TextStyle(
                    color: numberColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(BuildContext context) {
    return Container(
      width: 48,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildDateGrid(BuildContext context, List<VisitScheduleDay> days) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 122,
      ),
      itemBuilder: (context, index) => _buildDateTile(context, days[index]),
    );
  }

  Widget _buildSlotGrid(BuildContext context, List<String> slots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 52,
      ),
      itemBuilder: (context, index) => _buildSlotTile(context, slots[index]),
    );
  }

  Widget _buildMessageState(
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
}
