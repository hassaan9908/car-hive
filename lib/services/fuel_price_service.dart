import 'package:cloud_firestore/cloud_firestore.dart';

class FuelPriceEntry {
  final String type;
  final double price;
  final String unit;
  final double change;
  final DateTime? updatedAt;

  const FuelPriceEntry({
    required this.type,
    required this.price,
    required this.unit,
    required this.change,
    required this.updatedAt,
  });

  String get id => _normalizeType(type);

  String get arrowSymbol {
    if (change < 0) {
      return '▼';
    }
    if (change > 0) {
      return '▲';
    }
    return '—';
  }

  FuelPriceEntry copyWith({
    String? type,
    double? price,
    String? unit,
    double? change,
    DateTime? updatedAt,
  }) {
    return FuelPriceEntry(
      type: type ?? this.type,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      change: change ?? this.change,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'type': type,
      'price_per_liter': price,
      'change': change,
      'unit': unit,
      'updated_at': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }

  static FuelPriceEntry fromFirestore(Map<String, dynamic> data) {
    final type = (data['type'] ?? 'Unknown').toString();
    final normalizedType = type.toLowerCase();
    final unit =
        (data['unit'] ?? (normalizedType.contains('electric') ? 'kWh' : 'L'))
            .toString();

    return FuelPriceEntry(
      type: type,
      price:
          _toDouble(data['price_per_liter']) ?? _toDouble(data['price']) ?? 0,
      unit: unit,
      change: _toDouble(data['change']) ?? 0,
      updatedAt: _parseDateTime(data['updated_at'] ?? data['updatedAt']),
    );
  }
}

class FuelPricesPayload {
  final List<FuelPriceEntry> entries;
  final DateTime? lastUpdated;

  const FuelPricesPayload({
    required this.entries,
    required this.lastUpdated,
  });
}

class FuelPriceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static FuelPricesPayload? _cache;
  static DateTime? _cacheTimestamp;

  static const Duration cacheDuration = Duration(hours: 1);
  static const Map<String, int> _fuelOrder = <String, int>{
    'petrol_regular': 0,
    'hi_octane': 1,
    'diesel': 2,
    'cng': 3,
    'electric': 4,
  };

  Future<FuelPricesPayload> fetchFuelPrices({bool useCache = true}) async {
    final now = DateTime.now();

    if (useCache && _cache != null && _cacheTimestamp != null) {
      final age = now.difference(_cacheTimestamp!);
      if (age < cacheDuration) {
        return _cache!;
      }
    }

    try {
      final snapshot = await _firestore.collection('fuel_prices').get();
      final loadedEntries = snapshot.docs
          .map((doc) => FuelPriceEntry.fromFirestore(doc.data()))
          .toList();

      final entries = loadedEntries.isEmpty
          ? defaultFuelPrices()
          : sortEntries(loadedEntries);

      DateTime? latest;
      for (final entry in entries) {
        if (entry.updatedAt == null) {
          continue;
        }

        if (latest == null || entry.updatedAt!.isAfter(latest)) {
          latest = entry.updatedAt;
        }
      }

      final payload = FuelPricesPayload(
        entries: entries,
        lastUpdated: latest ?? now,
      );

      _cache = payload;
      _cacheTimestamp = now;
      return payload;
    } catch (_) {
      final fallback = defaultFuelPrices();
      final payload = FuelPricesPayload(
        entries: fallback,
        lastUpdated: now,
      );

      _cache = payload;
      _cacheTimestamp = now;
      return payload;
    }
  }

  Future<void> updateFuelPrice(FuelPriceEntry entry) async {
    final now = DateTime.now();
    final updatedEntry = entry.copyWith(updatedAt: now);

    await _firestore
        .collection('fuel_prices')
        .doc(updatedEntry.id)
        .set(updatedEntry.toFirestoreMap(), SetOptions(merge: true));

    invalidateCache();
  }

  Future<void> updateAllFuelPrices(List<FuelPriceEntry> entries) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    for (final entry in entries) {
      final updatedEntry = entry.copyWith(updatedAt: now);
      final ref = _firestore.collection('fuel_prices').doc(updatedEntry.id);
      batch.set(ref, updatedEntry.toFirestoreMap(), SetOptions(merge: true));
    }

    await batch.commit();
    invalidateCache();
  }

  static void invalidateCache() {
    _cache = null;
    _cacheTimestamp = null;
  }

  List<FuelPriceEntry> sortEntries(List<FuelPriceEntry> entries) {
    final sorted = List<FuelPriceEntry>.from(entries);
    sorted.sort((a, b) {
      final aOrder = _fuelOrder[a.id] ?? 999;
      final bOrder = _fuelOrder[b.id] ?? 999;
      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      return a.type.toLowerCase().compareTo(b.type.toLowerCase());
    });
    return sorted;
  }

  List<FuelPriceEntry> defaultFuelPrices() {
    final now = DateTime.now();
    return <FuelPriceEntry>[
      FuelPriceEntry(
        type: 'Petrol (Regular)',
        price: 287.48,
        unit: 'L',
        change: -2.12,
        updatedAt: now,
      ),
      FuelPriceEntry(
        type: 'Hi-Octane',
        price: 322.10,
        unit: 'L',
        change: 0,
        updatedAt: now,
      ),
      FuelPriceEntry(
        type: 'Diesel',
        price: 292.65,
        unit: 'L',
        change: 1.30,
        updatedAt: now,
      ),
      FuelPriceEntry(
        type: 'CNG',
        price: 240.00,
        unit: 'L',
        change: -0.80,
        updatedAt: now,
      ),
      FuelPriceEntry(
        type: 'Electric',
        price: 62.00,
        unit: 'kWh',
        change: 0.20,
        updatedAt: now,
      ),
    ];
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}

double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

String _normalizeType(String type) {
  return type
      .trim()
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
