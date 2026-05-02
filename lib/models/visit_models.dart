import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }
  return 0;
}

double _parseDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim()) ?? 0;
  }
  return 0;
}

String _parseString(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}

class VisitTimeSlot {
  final String label;
  final bool enabled;

  const VisitTimeSlot({
    required this.label,
    required this.enabled,
  });

  factory VisitTimeSlot.fromMap(Map<String, dynamic> data) {
    return VisitTimeSlot(
      label: _parseString(data['label']),
      enabled: data['enabled'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'label': label,
      'enabled': enabled,
    };
  }
}

class VisitScheduleDay {
  final String dateKey;
  final DateTime date;
  final bool isAvailable;
  final int capacity;
  final int bookedCount;
  final List<VisitTimeSlot> timeSlots;

  const VisitScheduleDay({
    required this.dateKey,
    required this.date,
    required this.isAvailable,
    required this.capacity,
    required this.bookedCount,
    required this.timeSlots,
  });

  factory VisitScheduleDay.fromMap(String dateKey, Map<String, dynamic> data) {
    final parsedDate = _parseDate(data['date']) ??
        DateTime.tryParse(dateKey) ??
        DateTime.now();
    final rawSlots = data['timeSlots'];
    final slots = <VisitTimeSlot>[];

    if (rawSlots is List) {
      for (final item in rawSlots) {
        if (item is Map<String, dynamic>) {
          slots.add(VisitTimeSlot.fromMap(item));
        } else if (item is Map) {
          slots.add(VisitTimeSlot.fromMap(Map<String, dynamic>.from(item)));
        } else if (item is String && item.trim().isNotEmpty) {
          slots.add(VisitTimeSlot(label: item.trim(), enabled: true));
        }
      }
    }

    slots.sort((a, b) => a.label.compareTo(b.label));

    return VisitScheduleDay(
      dateKey: dateKey,
      date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      isAvailable: data['isAvailable'] != false,
      capacity: _parseInt(data['capacity']),
      bookedCount: _parseInt(data['bookedCount']),
      timeSlots: slots,
    );
  }

  int get availableSeats => math.max(capacity - bookedCount, 0);

  bool get isFull => availableSeats <= 0;

  bool get hasEnabledSlots => enabledTimeSlots.isNotEmpty;

  bool get isInPast {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return date.isBefore(normalizedToday);
  }

  bool get isSelectable =>
      isAvailable && !isFull && hasEnabledSlots && !isInPast;

  List<String> get enabledTimeSlots => timeSlots
      .where((slot) => slot.enabled && slot.label.trim().isNotEmpty)
      .map((slot) => slot.label)
      .toList();

  String get statusLabel {
    if (!isAvailable) {
      return 'Off';
    }
    if (isFull) {
      return 'Full';
    }
    return '$availableSeats seat${availableSeats == 1 ? '' : 's'}';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'date': Timestamp.fromDate(date),
      'isAvailable': isAvailable,
      'capacity': capacity,
      'bookedCount': bookedCount,
      'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
    };
  }
}

class VisitSchedule {
  final String id;
  final String city;
  final List<String> areas;
  final Map<String, VisitScheduleDay> days;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VisitSchedule({
    required this.id,
    required this.city,
    required this.areas,
    required this.days,
    this.createdAt,
    this.updatedAt,
  });

  factory VisitSchedule.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawDays = data['dates'];
    final parsedDays = <String, VisitScheduleDay>{};

    if (rawDays is Map) {
      for (final entry in rawDays.entries) {
        if (entry.value is Map<String, dynamic>) {
          parsedDays[entry.key] = VisitScheduleDay.fromMap(
              entry.key, entry.value as Map<String, dynamic>);
        } else if (entry.value is Map) {
          parsedDays[entry.key] = VisitScheduleDay.fromMap(
            entry.key,
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    final areaList = <String>{
      for (final item in (data['areas'] as List? ?? const <dynamic>[]))
        _parseString(item),
    }.where((item) => item.isNotEmpty).toList()
      ..sort();

    return VisitSchedule(
      id: doc.id,
      city: _parseString(data['city']).isNotEmpty
          ? _parseString(data['city'])
          : doc.id,
      areas: areaList,
      days: parsedDays,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  List<VisitScheduleDay> get sortedDays {
    final items = days.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return items;
  }
}

class VisitBooking {
  final String id;
  final String userId;
  final String? carAdId;
  final String city;
  final String area;
  final DateTime? date;
  final String dateKey;
  final String timeSlot;
  final String paymentMethod;
  final double amount;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? carTitle;
  final String? carYear;
  final String? engine;
  final String? registeredCity;
  final String? assembly;
  final String? carImageUrl;
  final String rescheduleStatus;
  final String? pendingRescheduleRequestId;
  final DateTime? requestedRescheduleDate;
  final String? requestedRescheduleDateKey;
  final String? requestedRescheduleTimeSlot;
  final String? lastRescheduleStatus;
  final DateTime? lastRescheduleReviewedAt;

  const VisitBooking({
    required this.id,
    required this.userId,
    required this.carAdId,
    required this.city,
    required this.area,
    required this.date,
    required this.dateKey,
    required this.timeSlot,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.carTitle,
    required this.carYear,
    required this.engine,
    required this.registeredCity,
    required this.assembly,
    required this.carImageUrl,
    required this.rescheduleStatus,
    required this.pendingRescheduleRequestId,
    required this.requestedRescheduleDate,
    required this.requestedRescheduleDateKey,
    required this.requestedRescheduleTimeSlot,
    required this.lastRescheduleStatus,
    required this.lastRescheduleReviewedAt,
  });

  factory VisitBooking.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return VisitBooking(
      id: doc.id,
      userId: _parseString(data['userId']),
      carAdId: _parseString(data['carAdId']).isEmpty
          ? null
          : _parseString(data['carAdId']),
      city: _parseString(data['city']),
      area: _parseString(data['area']),
      date: _parseDate(data['date']),
      dateKey: _parseString(data['dateKey']),
      timeSlot: _parseString(data['timeSlot']),
      paymentMethod: _parseString(data['paymentMethod']),
      amount: _parseDouble(data['amount']),
      status: _parseString(data['status']).isEmpty
          ? 'booked'
          : _parseString(data['status']),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      carTitle: _parseString(data['carTitle']).isEmpty
          ? null
          : _parseString(data['carTitle']),
      carYear: _parseString(data['carYear']).isEmpty
          ? null
          : _parseString(data['carYear']),
      engine: _parseString(data['engine']).isEmpty
          ? null
          : _parseString(data['engine']),
      registeredCity: _parseString(data['registeredCity']).isEmpty
          ? null
          : _parseString(data['registeredCity']),
      assembly: _parseString(data['assembly']).isEmpty
          ? null
          : _parseString(data['assembly']),
      carImageUrl: _parseString(data['carImageUrl']).isEmpty
          ? null
          : _parseString(data['carImageUrl']),
      rescheduleStatus: _parseString(data['rescheduleStatus']).isEmpty
          ? 'none'
          : _parseString(data['rescheduleStatus']),
      pendingRescheduleRequestId:
          _parseString(data['pendingRescheduleRequestId']).isEmpty
              ? null
              : _parseString(data['pendingRescheduleRequestId']),
      requestedRescheduleDate: _parseDate(data['requestedRescheduleDate']),
      requestedRescheduleDateKey:
          _parseString(data['requestedRescheduleDateKey']).isEmpty
              ? null
              : _parseString(data['requestedRescheduleDateKey']),
      requestedRescheduleTimeSlot:
          _parseString(data['requestedRescheduleTimeSlot']).isEmpty
              ? null
              : _parseString(data['requestedRescheduleTimeSlot']),
      lastRescheduleStatus: _parseString(data['lastRescheduleStatus']).isEmpty
          ? null
          : _parseString(data['lastRescheduleStatus']),
      lastRescheduleReviewedAt: _parseDate(data['lastRescheduleReviewedAt']),
    );
  }

  DateTime? get normalizedDate {
    if (date == null) {
      return null;
    }
    return DateTime(date!.year, date!.month, date!.day);
  }

  bool get isCompleted {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return status == 'completed' ||
        (normalizedDate != null && normalizedDate!.isBefore(normalizedToday));
  }

  bool get isUpcoming => !isCompleted && status == 'booked';

  String get displayStatus {
    if (isCompleted) {
      return 'Completed';
    }
    return status == 'booked' ? 'Booked' : status;
  }

  String get displayTitle {
    final title = (carTitle ?? '').trim();
    if (title.isNotEmpty) {
      return title;
    }

    final parts = <String>[
      if ((carYear ?? '').trim().isNotEmpty) carYear!.trim(),
      'CarHive Assisted Visit',
    ];
    return parts.join(' ');
  }

  String get locationLabel => '$area, $city';

  String get formattedDateLabel {
    if (date == null) {
      return dateKey;
    }
    return DateFormat('dd MMM yyyy').format(date!);
  }
}

class RescheduleRequest {
  final String id;
  final String visitId;
  final String userId;
  final DateTime? requestedDate;
  final String requestedDateKey;
  final String requestedTimeSlot;
  final String status;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final DateTime? currentDate;
  final String? currentDateKey;
  final String? currentTimeSlot;
  final String? city;
  final String? area;
  final String? carTitle;

  const RescheduleRequest({
    required this.id,
    required this.visitId,
    required this.userId,
    required this.requestedDate,
    required this.requestedDateKey,
    required this.requestedTimeSlot,
    required this.status,
    required this.createdAt,
    required this.reviewedAt,
    required this.currentDate,
    required this.currentDateKey,
    required this.currentTimeSlot,
    required this.city,
    required this.area,
    required this.carTitle,
  });

  factory RescheduleRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return RescheduleRequest(
      id: doc.id,
      visitId: _parseString(data['visitId']),
      userId: _parseString(data['userId']),
      requestedDate: _parseDate(data['requestedDate']),
      requestedDateKey: _parseString(data['requestedDateKey']),
      requestedTimeSlot: _parseString(data['requestedTimeSlot']),
      status: _parseString(data['status']).isEmpty
          ? 'pending'
          : _parseString(data['status']),
      createdAt: _parseDate(data['createdAt']),
      reviewedAt: _parseDate(data['reviewedAt']),
      currentDate: _parseDate(data['currentDate']),
      currentDateKey: _parseString(data['currentDateKey']).isEmpty
          ? null
          : _parseString(data['currentDateKey']),
      currentTimeSlot: _parseString(data['currentTimeSlot']).isEmpty
          ? null
          : _parseString(data['currentTimeSlot']),
      city: _parseString(data['city']).isEmpty
          ? null
          : _parseString(data['city']),
      area: _parseString(data['area']).isEmpty
          ? null
          : _parseString(data['area']),
      carTitle: _parseString(data['carTitle']).isEmpty
          ? null
          : _parseString(data['carTitle']),
    );
  }
}

class AdminRescheduleRequestView {
  final RescheduleRequest request;
  final VisitBooking? visit;
  final String userName;
  final int availableSeats;

  const AdminRescheduleRequestView({
    required this.request,
    required this.visit,
    required this.userName,
    required this.availableSeats,
  });
}
