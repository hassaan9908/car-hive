import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/visit_models.dart';
import '../../services/visit_service.dart';
import '../../theme/app_colors.dart';

class AdminVisitSchedulePage extends StatefulWidget {
  const AdminVisitSchedulePage({super.key});

  @override
  State<AdminVisitSchedulePage> createState() => _AdminVisitSchedulePageState();
}

class _AdminVisitSchedulePageState extends State<AdminVisitSchedulePage> {
  final VisitService _visitService = VisitService();
  String? _selectedCityId;
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Visit Schedules'),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isBusy ? null : _showAddCityDialog,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add City'),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<VisitSchedule>>(
        stream: _visitService.watchSchedules(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildMessage(
              context,
              icon: Icons.error_outline,
              title: 'Could not load visit schedules',
              subtitle: snapshot.error.toString(),
            );
          }

          final schedules = snapshot.data ?? <VisitSchedule>[];
          if (schedules.isEmpty) {
            return _buildMessage(
              context,
              icon: Icons.event_busy_outlined,
              title: 'No visit schedules yet',
              subtitle: 'Add a city to start managing visit dates and slots.',
              action: FilledButton.icon(
                onPressed: _isBusy ? null : _showAddCityDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create First City'),
              ),
            );
          }

          _selectedCityId ??= schedules.first.id;
          if (!schedules.any((schedule) => schedule.id == _selectedCityId)) {
            _selectedCityId = schedules.first.id;
          }
          final selectedSchedule = schedules.firstWhere(
            (schedule) => schedule.id == _selectedCityId,
          );

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  color: theme.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      runSpacing: 16,
                      spacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 280,
                          child: DropdownButtonFormField<String>(
                            value: selectedSchedule.id,
                            decoration: const InputDecoration(
                              labelText: 'Selected city',
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                            items: schedules
                                .map(
                                  (schedule) => DropdownMenuItem<String>(
                                    value: schedule.id,
                                    child: Text(schedule.city),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedCityId = value;
                              });
                            },
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isBusy
                              ? null
                              : () => _showDeleteCityDialog(selectedSchedule),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove City'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: theme.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Areas',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (selectedSchedule.areas.isEmpty)
                          Text(
                            'No areas added for this city yet.',
                            style: theme.textTheme.bodyMedium,
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: selectedSchedule.areas
                                .map(
                                  (area) => InputChip(
                                    label: Text(area),
                                    onDeleted: _isBusy
                                        ? null
                                        : () => _removeArea(
                                              selectedSchedule.city,
                                              area,
                                            ),
                                  ),
                                )
                                .toList(),
                          ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _isBusy
                                ? null
                                : () =>
                                    _showAddAreaDialog(selectedSchedule.city),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Area'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: theme.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Dates and Time Slots',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.greenAction,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isBusy
                                  ? null
                                  : () => _showDayEditor(
                                        selectedSchedule.city,
                                      ),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Date'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (selectedSchedule.sortedDays.isEmpty)
                          Text(
                            'No dates configured yet. Add a date to publish availability.',
                            style: theme.textTheme.bodyMedium,
                          )
                        else
                          Column(
                            children: selectedSchedule.sortedDays
                                .map(
                                  (day) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildDayCard(
                                      context,
                                      selectedSchedule,
                                      day,
                                      colorScheme,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    VisitSchedule schedule,
    VisitScheduleDay day,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);
    final statusColor = !day.isAvailable
        ? colorScheme.error
        : day.isFull
            ? Colors.orange
            : colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMM yyyy').format(day.date),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusPill(
                          label: day.isAvailable
                              ? (day.isFull ? 'Full' : 'Accepting Visits')
                              : 'Blocked',
                          color: statusColor,
                        ),
                        _StatusPill(
                          label:
                              '${day.capacity} total · ${day.availableSeats} free',
                          color: colorScheme.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showDayEditor(schedule.city, existing: day);
                      } else if (value == 'add-slot') {
                        _showAddTimeSlotDialog(schedule.city, day);
                      } else if (value == 'delete') {
                        _deleteDay(schedule.city, day.dateKey);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit Date'),
                      ),
                      PopupMenuItem<String>(
                        value: 'add-slot',
                        child: Text('Add Time Slot'),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Remove Date'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Accepting Visits',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 6),
                      Switch(
                        value: day.isAvailable,
                        onChanged: _isBusy
                            ? null
                            : (value) =>
                                _setDayAvailability(schedule.city, day, value),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (day.timeSlots.isEmpty)
            Text(
              'No time slots configured.',
              style: theme.textTheme.bodyMedium,
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: day.timeSlots
                  .map(
                    (slot) => FilterChip(
                      label: Text(slot.label),
                      selected: slot.enabled,
                      showCheckmark: slot.enabled,
                      checkmarkColor: theme.colorScheme.primary,
                      selectedColor:
                          theme.colorScheme.primary.withValues(alpha: 0.14),
                      onSelected: _isBusy
                          ? null
                          : (enabled) => _toggleTimeSlot(
                                schedule.city,
                                day,
                                slot.label,
                                enabled,
                              ),
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: slot.enabled
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyMedium?.color,
                        fontWeight:
                            slot.enabled ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
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
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCityDialog() async {
    final cityController = TextEditingController();
    final areasController = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add City Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City name',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: areasController,
                decoration: const InputDecoration(
                  labelText: 'Areas',
                  helperText: 'Separate multiple areas with commas.',
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    final areas = areasController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    await _runBusyAction(
      () => _visitService.addCity(cityController.text, areas: areas),
      successMessage: 'City schedule created.',
    );
  }

  Future<void> _showDeleteCityDialog(VisitSchedule schedule) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove City'),
          content: Text(
            'Delete the visit schedule for ${schedule.city}? This removes all areas and date availability for that city.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await _runBusyAction(
      () => _visitService.removeCity(schedule.city),
      successMessage: 'City schedule removed.',
    );
  }

  Future<void> _showAddAreaDialog(String city) async {
    final controller = TextEditingController();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Area'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Area name'),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    await _runBusyAction(
      () => _visitService.addArea(city, controller.text),
      successMessage: 'Area added.',
    );
  }

  Future<void> _removeArea(String city, String area) async {
    await _runBusyAction(
      () => _visitService.removeArea(city, area),
      successMessage: 'Area removed.',
    );
  }

  Future<void> _deleteDay(String city, String dateKey) async {
    await _runBusyAction(
      () => _visitService.removeScheduleDay(city, dateKey),
      successMessage: 'Date removed from schedule.',
    );
  }

  Future<void> _setDayAvailability(
    String city,
    VisitScheduleDay day,
    bool isAvailable,
  ) async {
    final updatedDay = VisitScheduleDay(
      dateKey: day.dateKey,
      date: day.date,
      isAvailable: isAvailable,
      capacity: day.capacity,
      bookedCount: day.bookedCount,
      timeSlots: day.timeSlots,
    );

    await _runBusyAction(
      () => _visitService.upsertScheduleDay(city, updatedDay),
      successMessage: isAvailable
          ? 'Date is now accepting visits.'
          : 'Date blocked for visits.',
    );
  }

  Future<void> _toggleTimeSlot(
    String city,
    VisitScheduleDay day,
    String slotLabel,
    bool enabled,
  ) async {
    final updatedSlots = day.timeSlots
        .map(
          (slot) =>
              slot.label.trim().toLowerCase() == slotLabel.trim().toLowerCase()
                  ? VisitTimeSlot(label: slot.label, enabled: enabled)
                  : slot,
        )
        .toList();

    final updatedDay = VisitScheduleDay(
      dateKey: day.dateKey,
      date: day.date,
      isAvailable: day.isAvailable,
      capacity: day.capacity,
      bookedCount: day.bookedCount,
      timeSlots: updatedSlots,
    );

    await _runBusyAction(
      () => _visitService.upsertScheduleDay(city, updatedDay),
      successMessage: enabled ? 'Time slot enabled.' : 'Time slot disabled.',
    );
  }

  Future<void> _showAddTimeSlotDialog(
    String city,
    VisitScheduleDay day,
  ) async {
    final controller = TextEditingController();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Time Slot'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Time slot',
              hintText: '09:30 AM',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    final label = controller.text.trim();
    if (label.isEmpty) {
      _showSnackBar('Please enter a time slot.', isError: true);
      return;
    }
    if (day.timeSlots.any(
      (slot) => slot.label.trim().toLowerCase() == label.toLowerCase(),
    )) {
      _showSnackBar('That time slot already exists.', isError: true);
      return;
    }

    final updatedDay = VisitScheduleDay(
      dateKey: day.dateKey,
      date: day.date,
      isAvailable: day.isAvailable,
      capacity: day.capacity,
      bookedCount: day.bookedCount,
      timeSlots: <VisitTimeSlot>[
        ...day.timeSlots,
        VisitTimeSlot(label: label, enabled: true),
      ],
    );

    await _runBusyAction(
      () => _visitService.upsertScheduleDay(city, updatedDay),
      successMessage: 'Time slot added.',
    );
  }

  Future<void> _showDayEditor(
    String city, {
    VisitScheduleDay? existing,
  }) async {
    final draft = _VisitDayDraft.fromExisting(existing);
    final capacityController =
        TextEditingController(text: draft.capacity.toString());
    final slotController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: draft.date,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked == null) {
                return;
              }
              setState(() {
                draft.date = DateTime(picked.year, picked.month, picked.day);
              });
            }

            return AlertDialog(
              title: Text(existing == null ? 'Add Date' : 'Edit Date'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text(
                          DateFormat('EEEE, dd MMM yyyy').format(draft.date),
                        ),
                        subtitle: const Text('Booking date'),
                        trailing: TextButton(
                          onPressed: pickDate,
                          child: const Text('Change'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date available'),
                        subtitle: const Text(
                          'Turn this off to block the date for users.',
                        ),
                        value: draft.isAvailable,
                        onChanged: (value) {
                          setState(() {
                            draft.isAvailable = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: capacityController,
                        decoration: const InputDecoration(
                          labelText: 'Capacity',
                          helperText: 'Total seats available on this date.',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Time slots',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: slotController,
                              decoration: const InputDecoration(
                                labelText: 'Add time slot',
                                hintText: '09:30 AM',
                              ),
                              textCapitalization: TextCapitalization.characters,
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.tonal(
                            onPressed: () {
                              final label = slotController.text.trim();
                              if (label.isEmpty) {
                                return;
                              }
                              setState(() {
                                draft.addSlot(label);
                                slotController.clear();
                              });
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (draft.timeSlots.isEmpty)
                        Text(
                          'Add at least one time slot for this date.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        Column(
                          children: draft.timeSlots
                              .map(
                                (slot) => CheckboxListTile(
                                  value: slot.enabled,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(slot.label),
                                  subtitle: Text(
                                    slot.enabled ? 'Enabled' : 'Disabled',
                                  ),
                                  secondary: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        draft.removeSlot(slot.label);
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      draft.toggleSlot(
                                          slot.label, value ?? false);
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsedCapacity =
                        int.tryParse(capacityController.text.trim()) ?? 0;
                    if (parsedCapacity <= 0) {
                      _showSnackBar(
                        'Capacity must be greater than zero.',
                        isError: true,
                      );
                      return;
                    }
                    if (draft.timeSlots.isEmpty) {
                      _showSnackBar(
                        'Add at least one time slot.',
                        isError: true,
                      );
                      return;
                    }
                    draft.capacity = parsedCapacity;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      return;
    }

    final day = VisitScheduleDay(
      dateKey: _visitService.dateKeyFor(draft.date),
      date: draft.date,
      isAvailable: draft.isAvailable,
      capacity: draft.capacity,
      bookedCount: existing?.bookedCount ?? 0,
      timeSlots: draft.timeSlots,
    );

    await _runBusyAction(
      () => _visitService.upsertScheduleDay(city, day),
      successMessage: existing == null ? 'Date added.' : 'Date updated.',
    );
  }

  Future<void> _runBusyAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      _showSnackBar(successMessage);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
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

class _VisitDayDraft {
  DateTime date;
  bool isAvailable;
  int capacity;
  List<VisitTimeSlot> timeSlots;

  _VisitDayDraft({
    required this.date,
    required this.isAvailable,
    required this.capacity,
    required this.timeSlots,
  });

  factory _VisitDayDraft.fromExisting(VisitScheduleDay? existing) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _VisitDayDraft(
      date: existing?.date ??
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
      isAvailable: existing?.isAvailable ?? true,
      capacity: existing?.capacity ?? 4,
      timeSlots: existing?.timeSlots.toList() ??
          <VisitTimeSlot>[
            const VisitTimeSlot(label: '09:30 AM', enabled: true),
            const VisitTimeSlot(label: '11:00 AM', enabled: true),
            const VisitTimeSlot(label: '01:30 PM', enabled: true),
            const VisitTimeSlot(label: '03:30 PM', enabled: true),
          ],
    );
  }

  void addSlot(String label) {
    if (timeSlots.any(
      (slot) => slot.label.trim().toLowerCase() == label.trim().toLowerCase(),
    )) {
      return;
    }
    timeSlots = <VisitTimeSlot>[
      ...timeSlots,
      VisitTimeSlot(label: label.trim(), enabled: true),
    ];
  }

  void removeSlot(String label) {
    timeSlots = timeSlots
        .where((slot) =>
            slot.label.trim().toLowerCase() != label.trim().toLowerCase())
        .toList();
  }

  void toggleSlot(String label, bool enabled) {
    timeSlots = timeSlots
        .map(
          (slot) =>
              slot.label.trim().toLowerCase() == label.trim().toLowerCase()
                  ? VisitTimeSlot(label: slot.label, enabled: enabled)
                  : slot,
        )
        .toList();
  }
}
