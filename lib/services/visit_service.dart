import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/visit_models.dart';

class VisitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _scheduleCollection =>
      _firestore.collection('visitSchedules');

  CollectionReference<Map<String, dynamic>> get _visitsCollection =>
      _firestore.collection('visits');

  CollectionReference<Map<String, dynamic>> get _rescheduleCollection =>
      _firestore.collection('rescheduleRequests');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('visitNotifications');

  String scheduleIdForCity(String city) {
    return city
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String dateKeyFor(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return DateFormat('yyyy-MM-dd').format(normalized);
  }

  Stream<List<VisitSchedule>> watchSchedules() {
    return _scheduleCollection.snapshots().map((snapshot) {
      final schedules = snapshot.docs.map(VisitSchedule.fromFirestore).toList()
        ..sort((a, b) => a.city.compareTo(b.city));
      return schedules;
    });
  }

  Stream<VisitSchedule?> watchScheduleForCity(String city) {
    return _scheduleCollection
        .doc(scheduleIdForCity(city))
        .snapshots()
        .map((doc) => doc.exists ? VisitSchedule.fromFirestore(doc) : null);
  }

  Future<VisitSchedule?> getScheduleForCity(String city) async {
    final doc = await _scheduleCollection.doc(scheduleIdForCity(city)).get();
    if (!doc.exists) {
      return null;
    }
    return VisitSchedule.fromFirestore(doc);
  }

  Future<void> addCity(String city,
      {List<String> areas = const <String>[]}) async {
    final trimmedCity = city.trim();
    if (trimmedCity.isEmpty) {
      throw Exception('City name is required.');
    }

    final docRef = _scheduleCollection.doc(scheduleIdForCity(trimmedCity));
    final existing = await docRef.get();
    if (existing.exists) {
      throw Exception('A schedule for $trimmedCity already exists.');
    }

    final normalizedAreas = _normalizeAreas(areas);
    await docRef.set(<String, dynamic>{
      'city': trimmedCity,
      'areas': normalizedAreas,
      'dates': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeCity(String city) async {
    await _scheduleCollection.doc(scheduleIdForCity(city)).delete();
  }

  Future<void> addArea(String city, String area) async {
    final docRef = _scheduleCollection.doc(scheduleIdForCity(city));
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('Visit schedule for $city was not found.');
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    final areas = _normalizeAreas(
      List<String>.from(data['areas'] as List? ?? const <String>[]),
      additional: <String>[area],
    );

    await docRef.update(<String, dynamic>{
      'areas': areas,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeArea(String city, String area) async {
    final docRef = _scheduleCollection.doc(scheduleIdForCity(city));
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('Visit schedule for $city was not found.');
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    final currentAreas =
        List<String>.from(data['areas'] as List? ?? const <String>[]);
    currentAreas.removeWhere(
      (item) => item.trim().toLowerCase() == area.trim().toLowerCase(),
    );

    await docRef.update(<String, dynamic>{
      'areas': _normalizeAreas(currentAreas),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> upsertScheduleDay(String city, VisitScheduleDay day) async {
    final docRef = _scheduleCollection.doc(scheduleIdForCity(city));
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('Visit schedule for $city was not found.');
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    final dates = _copyDatesMap(data['dates']);
    final currentDayRaw = Map<String, dynamic>.from(
      dates[day.dateKey] as Map? ?? <String, dynamic>{},
    );
    final currentBookedCount = _asInt(currentDayRaw['bookedCount']);
    final normalizedDay = VisitScheduleDay(
      dateKey: day.dateKey,
      date: day.date,
      isAvailable: day.isAvailable,
      capacity: math.max(day.capacity, currentBookedCount),
      bookedCount: currentBookedCount,
      timeSlots: day.timeSlots,
    );

    dates[day.dateKey] = normalizedDay.toMap();

    await docRef.update(<String, dynamic>{
      'dates': dates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeScheduleDay(String city, String dateKey) async {
    final docRef = _scheduleCollection.doc(scheduleIdForCity(city));
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('Visit schedule for $city was not found.');
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    final dates = _copyDatesMap(data['dates']);
    dates.remove(dateKey);

    await docRef.update(<String, dynamic>{
      'dates': dates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> createVisitBooking({
    required String city,
    required String area,
    required DateTime date,
    required String timeSlot,
    required String paymentMethod,
    required double amount,
    String? carAdId,
    String? carTitle,
    String? carYear,
    String? engine,
    String? registeredCity,
    String? assembly,
    String? carImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please log in to book a visit.');
    }

    final normalizedCity = city.trim();
    final normalizedArea = area.trim();
    final normalizedSlot = timeSlot.trim();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dateKey = dateKeyFor(normalizedDate);
    final visitRef = _visitsCollection.doc();
    final scheduleRef =
        _scheduleCollection.doc(scheduleIdForCity(normalizedCity));

    await _firestore.runTransaction((transaction) async {
      final scheduleSnapshot = await transaction.get(scheduleRef);
      if (!scheduleSnapshot.exists) {
        throw Exception(
            'This city is not available for visit bookings right now.');
      }

      final scheduleData = scheduleSnapshot.data() ?? <String, dynamic>{};
      final areas = List<String>.from(
        scheduleData['areas'] as List? ?? const <String>[],
      );
      if (!areas.any(
        (item) => item.trim().toLowerCase() == normalizedArea.toLowerCase(),
      )) {
        throw Exception('The selected area is no longer available.');
      }

      final dates = _copyDatesMap(scheduleData['dates']);
      final dayRaw = Map<String, dynamic>.from(
        dates[dateKey] as Map? ?? <String, dynamic>{},
      );
      if (dayRaw.isEmpty) {
        throw Exception('The selected date is no longer available.');
      }

      final day = VisitScheduleDay.fromMap(dateKey, dayRaw);
      if (!day.isAvailable || day.isFull) {
        throw Exception('This date is no longer available.');
      }

      final enabledSlots = day.enabledTimeSlots;
      if (!enabledSlots.contains(normalizedSlot)) {
        throw Exception('The selected time slot is no longer available.');
      }

      dates[dateKey] = <String, dynamic>{
        ...dayRaw,
        'bookedCount': day.bookedCount + 1,
      };

      transaction.update(scheduleRef, <String, dynamic>{
        'dates': dates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(visitRef, <String, dynamic>{
        'userId': user.uid,
        'carAdId': carAdId,
        'city': normalizedCity,
        'area': normalizedArea,
        'date': Timestamp.fromDate(normalizedDate),
        'dateKey': dateKey,
        'timeSlot': normalizedSlot,
        'paymentMethod': paymentMethod,
        'amount': amount,
        'status': 'booked',
        'carTitle': carTitle,
        'carYear': carYear,
        'engine': engine,
        'registeredCity': registeredCity,
        'assembly': assembly,
        'carImageUrl': carImageUrl,
        'rescheduleStatus': 'none',
        'pendingRescheduleRequestId': null,
        'requestedRescheduleDate': null,
        'requestedRescheduleDateKey': null,
        'requestedRescheduleTimeSlot': null,
        'lastRescheduleStatus': null,
        'lastRescheduleReviewedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return visitRef.id;
  }

  Stream<List<VisitBooking>> watchAllVisits() {
    return _visitsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(VisitBooking.fromFirestore).toList());
  }

  Future<String> getUserDisplayName(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return userId;
      return _resolveUserName(doc.data() ?? <String, dynamic>{});
    } catch (_) {
      return userId;
    }
  }

  Stream<List<VisitBooking>> watchUserVisits(String userId) {
    return _visitsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final visits = snapshot.docs.map(VisitBooking.fromFirestore).toList()
        ..sort((a, b) {
          final aDate =
              a.date ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              b.date ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      return visits;
    });
  }

  Future<void> requestReschedule({
    required VisitBooking visit,
    required DateTime requestedDate,
    required String requestedTimeSlot,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please log in to request a reschedule.');
    }
    if (user.uid != visit.userId) {
      throw Exception('You can only reschedule your own visits.');
    }

    final normalizedDate =
        DateTime(requestedDate.year, requestedDate.month, requestedDate.day);
    final requestedDateKey = dateKeyFor(normalizedDate);
    final normalizedSlot = requestedTimeSlot.trim();
    final visitRef = _visitsCollection.doc(visit.id);
    final requestRef = _rescheduleCollection.doc();
    final scheduleRef = _scheduleCollection.doc(scheduleIdForCity(visit.city));

    await _firestore.runTransaction((transaction) async {
      final visitSnapshot = await transaction.get(visitRef);
      if (!visitSnapshot.exists) {
        throw Exception('The visit could not be found.');
      }

      final freshVisit = VisitBooking.fromFirestore(visitSnapshot);
      if (freshVisit.rescheduleStatus == 'pending') {
        throw Exception(
            'A reschedule request is already pending for this visit.');
      }
      if (freshVisit.dateKey == requestedDateKey &&
          freshVisit.timeSlot.trim() == normalizedSlot) {
        throw Exception('Please choose a different date or time slot.');
      }

      final scheduleSnapshot = await transaction.get(scheduleRef);
      if (!scheduleSnapshot.exists) {
        throw Exception(
            'This city is not available for rescheduling right now.');
      }

      final scheduleData = scheduleSnapshot.data() ?? <String, dynamic>{};
      final dates = _copyDatesMap(scheduleData['dates']);
      final dayRaw = Map<String, dynamic>.from(
        dates[requestedDateKey] as Map? ?? <String, dynamic>{},
      );
      if (dayRaw.isEmpty) {
        throw Exception('The requested date is no longer available.');
      }

      final day = VisitScheduleDay.fromMap(requestedDateKey, dayRaw);
      final sameDate = freshVisit.dateKey == requestedDateKey;
      if (!day.isAvailable || (!sameDate && day.isFull)) {
        throw Exception('The requested date is full or unavailable.');
      }
      if (!day.enabledTimeSlots.contains(normalizedSlot)) {
        throw Exception('The requested time slot is unavailable.');
      }

      transaction.set(requestRef, <String, dynamic>{
        'visitId': freshVisit.id,
        'userId': user.uid,
        'requestedDate': Timestamp.fromDate(normalizedDate),
        'requestedDateKey': requestedDateKey,
        'requestedTimeSlot': normalizedSlot,
        'status': 'pending',
        'currentDate': freshVisit.date == null
            ? null
            : Timestamp.fromDate(freshVisit.date!),
        'currentDateKey': freshVisit.dateKey,
        'currentTimeSlot': freshVisit.timeSlot,
        'city': freshVisit.city,
        'area': freshVisit.area,
        'carTitle': freshVisit.displayTitle,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(visitRef, <String, dynamic>{
        'rescheduleStatus': 'pending',
        'pendingRescheduleRequestId': requestRef.id,
        'requestedRescheduleDate': Timestamp.fromDate(normalizedDate),
        'requestedRescheduleDateKey': requestedDateKey,
        'requestedRescheduleTimeSlot': normalizedSlot,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<AdminRescheduleRequestView>> watchPendingRescheduleRequests() {
    return _rescheduleCollection.snapshots().asyncMap((snapshot) async {
      final requests = snapshot.docs
          .map(RescheduleRequest.fromFirestore)
          .where((request) => request.status == 'pending')
          .toList()
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      if (requests.isEmpty) {
        return <AdminRescheduleRequestView>[];
      }

      final visitIds = requests.map((request) => request.visitId).toSet();
      final userIds = requests.map((request) => request.userId).toSet();
      final cityIds = <String>{
        for (final request in requests)
          if ((request.city ?? '').trim().isNotEmpty)
            scheduleIdForCity(request.city!)
      };

      final visitSnapshots = await Future.wait(
        visitIds.map((id) => _visitsCollection.doc(id).get()),
      );
      final userSnapshots = await Future.wait(
        userIds.map((id) => _usersCollection.doc(id).get()),
      );
      final scheduleSnapshots = await Future.wait(
        cityIds.map((id) => _scheduleCollection.doc(id).get()),
      );

      final visitMap = <String, VisitBooking>{
        for (final doc in visitSnapshots)
          if (doc.exists) doc.id: VisitBooking.fromFirestore(doc),
      };
      final userNameMap = <String, String>{
        for (final doc in userSnapshots)
          doc.id: _resolveUserName(doc.data() ?? <String, dynamic>{}),
      };
      final scheduleMap = <String, VisitSchedule>{
        for (final doc in scheduleSnapshots)
          if (doc.exists) doc.id: VisitSchedule.fromFirestore(doc),
      };

      return requests.map((request) {
        final visit = visitMap[request.visitId];
        final schedule = (request.city ?? '').trim().isEmpty
            ? null
            : scheduleMap[scheduleIdForCity(request.city!)];
        final day = schedule?.days[request.requestedDateKey];

        return AdminRescheduleRequestView(
          request: request,
          visit: visit,
          userName: userNameMap[request.userId] ?? 'User',
          availableSeats: day?.availableSeats ?? 0,
        );
      }).toList();
    });
  }

  Future<void> acceptReschedule(String requestId) async {
    final requestRef = _rescheduleCollection.doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw Exception('The reschedule request could not be found.');
      }

      final request = RescheduleRequest.fromFirestore(requestSnapshot);
      if (request.status != 'pending') {
        throw Exception('This reschedule request has already been reviewed.');
      }

      final visitRef = _visitsCollection.doc(request.visitId);
      final visitSnapshot = await transaction.get(visitRef);
      if (!visitSnapshot.exists) {
        throw Exception('The visit linked to this request could not be found.');
      }

      final visit = VisitBooking.fromFirestore(visitSnapshot);
      final scheduleRef =
          _scheduleCollection.doc(scheduleIdForCity(visit.city));
      final scheduleSnapshot = await transaction.get(scheduleRef);
      if (!scheduleSnapshot.exists) {
        throw Exception('The city schedule could not be found.');
      }

      final scheduleData = scheduleSnapshot.data() ?? <String, dynamic>{};
      final dates = _copyDatesMap(scheduleData['dates']);

      final requestedDayRaw = Map<String, dynamic>.from(
        dates[request.requestedDateKey] as Map? ?? <String, dynamic>{},
      );
      if (requestedDayRaw.isEmpty) {
        throw Exception('The requested date is no longer available.');
      }

      final requestedDay =
          VisitScheduleDay.fromMap(request.requestedDateKey, requestedDayRaw);
      if (!requestedDay.isAvailable) {
        throw Exception('The requested date is marked off.');
      }
      if (!requestedDay.enabledTimeSlots.contains(request.requestedTimeSlot)) {
        throw Exception('The requested time slot is no longer available.');
      }

      final sameDate = visit.dateKey == request.requestedDateKey;
      if (!sameDate && requestedDay.availableSeats <= 0) {
        throw Exception('The requested date is already full.');
      }

      if (!sameDate) {
        final currentDayRaw = Map<String, dynamic>.from(
          dates[visit.dateKey] as Map? ?? <String, dynamic>{},
        );
        if (currentDayRaw.isNotEmpty) {
          final currentDay =
              VisitScheduleDay.fromMap(visit.dateKey, currentDayRaw);
          dates[visit.dateKey] = <String, dynamic>{
            ...currentDayRaw,
            'bookedCount': math.max(currentDay.bookedCount - 1, 0),
          };
        }

        dates[request.requestedDateKey] = <String, dynamic>{
          ...requestedDayRaw,
          'bookedCount': requestedDay.bookedCount + 1,
        };

        transaction.update(scheduleRef, <String, dynamic>{
          'dates': dates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(visitRef, <String, dynamic>{
        'date': request.requestedDate == null
            ? visit.date == null
                ? null
                : Timestamp.fromDate(visit.date!)
            : Timestamp.fromDate(request.requestedDate!),
        'dateKey': request.requestedDateKey,
        'timeSlot': request.requestedTimeSlot,
        'rescheduleStatus': 'accepted',
        'lastRescheduleStatus': 'accepted',
        'lastRescheduleReviewedAt': FieldValue.serverTimestamp(),
        'pendingRescheduleRequestId': null,
        'requestedRescheduleDate': null,
        'requestedRescheduleDateKey': null,
        'requestedRescheduleTimeSlot': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(requestRef, <String, dynamic>{
        'status': 'accepted',
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final notificationRef = _notificationsCollection.doc();
      transaction.set(notificationRef, <String, dynamic>{
        'userId': request.userId,
        'visitId': request.visitId,
        'requestId': request.id,
        'type': 'visit_reschedule',
        'title': 'Reschedule accepted',
        'message':
            'Your visit has been moved to ${request.requestedDateKey} at ${request.requestedTimeSlot}.',
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectReschedule(String requestId) async {
    final requestRef = _rescheduleCollection.doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw Exception('The reschedule request could not be found.');
      }

      final request = RescheduleRequest.fromFirestore(requestSnapshot);
      if (request.status != 'pending') {
        throw Exception('This reschedule request has already been reviewed.');
      }

      final visitRef = _visitsCollection.doc(request.visitId);
      final visitSnapshot = await transaction.get(visitRef);
      if (visitSnapshot.exists) {
        transaction.update(visitRef, <String, dynamic>{
          'rescheduleStatus': 'rejected',
          'lastRescheduleStatus': 'rejected',
          'lastRescheduleReviewedAt': FieldValue.serverTimestamp(),
          'pendingRescheduleRequestId': null,
          'requestedRescheduleDate': null,
          'requestedRescheduleDateKey': null,
          'requestedRescheduleTimeSlot': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(requestRef, <String, dynamic>{
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final notificationRef = _notificationsCollection.doc();
      transaction.set(notificationRef, <String, dynamic>{
        'userId': request.userId,
        'visitId': request.visitId,
        'requestId': request.id,
        'type': 'visit_reschedule',
        'title': 'Reschedule rejected',
        'message':
            'Your visit remains on the original schedule. The new requested slot could not be approved.',
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  List<String> _normalizeAreas(
    List<String> areas, {
    List<String> additional = const <String>[],
  }) {
    final normalized = <String>{
      for (final item in <String>[...areas, ...additional])
        if (item.trim().isNotEmpty) item.trim(),
    }.toList()
      ..sort();
    return normalized;
  }

  Map<String, dynamic> _copyDatesMap(dynamic rawDates) {
    if (rawDates is Map<String, dynamic>) {
      return Map<String, dynamic>.from(rawDates);
    }
    if (rawDates is Map) {
      return Map<String, dynamic>.from(rawDates);
    }
    return <String, dynamic>{};
  }

  int _asInt(dynamic value) {
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

  String _resolveUserName(Map<String, dynamic> data) {
    final displayName = (data['displayName'] ?? '').toString().trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }

    final fullName = (data['fullName'] ?? '').toString().trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final email = (data['email'] ?? '').toString().trim();
    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'User';
  }
}
