import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String title;
  final String price;
  final String location;
  final String year;
  final String mileage;
  final String fuel;
  late final String status; // 'active', 'pending', 'removed', 'sold'
  final String? userId;
  final String? id; // Firestore document ID
  final DateTime? createdAt;
  final String? description;
  final String? carBrand;
  final String? bodyColor;
  final String? kmsDriven;
  final String? registeredIn;
  final String? name;
  final String? phone;
  final String? previousStatus; // used to restore from removed to prior state
  final List<String>? imageUrls; // Cloudinary image URLs

  AdModel({
    required this.title,
    required this.price,
    required this.location,
    required this.year,
    required this.mileage,
    required this.fuel,
    this.status = 'active',
    this.userId,
    this.id,
    this.createdAt,
    this.description,
    this.carBrand,
    this.bodyColor,
    this.kmsDriven,
    this.registeredIn,
    this.name,
    this.phone,
    this.previousStatus,
    this.imageUrls,
  });

  static DateTime? _parseCreatedAt(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    if (value is int) {
      try {
        // Heuristic: values less than 1e12 are seconds; otherwise milliseconds
        if (value < 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(value * 1000);
        }
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    // Common patterns where a map is stored instead of a string
    if (value is Map) {
      final v =
          value['name'] ?? value['title'] ?? value['city'] ?? value['value'];
      if (v is String) return v;
    }
    return value.toString();
  }

  static List<String>? _parseImageUrls(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      final List<String> out = [];
      for (final item in raw) {
        if (item == null) continue;
        if (item is String) {
          out.add(item);
        } else if (item is Map) {
          final url = item['secure_url'] ??
              item['secureUrl'] ??
              item['url'] ??
              item['path'];
          if (url is String && url.isNotEmpty) out.add(url);
        }
      }
      return out.isEmpty ? null : out;
    }
    // Single string
    if (raw is String && raw.isNotEmpty) return [raw];
    return null;
  }

  // Factory constructor to create AdModel from Firestore document
  factory AdModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Parse imageUrls from Firestore with backward compatibility
    final imageUrlsList = _parseImageUrls(
      data['imageUrls'] ?? data['images'] ?? data['photos'],
    );

    return AdModel(
      id: documentId,
      title: _asString(data['title']),
      price: _asString(data['price']),
      location: _asString(data['location']),
      year: _asString(data['year']),
      mileage: _asString(data['mileage'] ?? data['kmsDriven']),
      fuel: _asString(data['fuel']),
      status: _asString(data['status']).isEmpty
          ? 'active'
          : _asString(data['status']),
      userId:
          _asString(data['userId']).isEmpty ? null : _asString(data['userId']),
      createdAt: _parseCreatedAt(data['createdAt'] ?? data['created_at']),
      description: (data['description'] is String)
          ? data['description'] as String
          : _asString(data['description']).isEmpty
              ? null
              : _asString(data['description']),
      carBrand: (data['carBrand'] is String)
          ? data['carBrand'] as String
          : _asString(data['carBrand']).isEmpty
              ? null
              : _asString(data['carBrand']),
      bodyColor: (data['bodyColor'] is String)
          ? data['bodyColor'] as String
          : _asString(data['bodyColor']).isEmpty
              ? null
              : _asString(data['bodyColor']),
      kmsDriven: (data['kmsDriven'] is String)
          ? data['kmsDriven'] as String
          : _asString(data['kmsDriven']).isEmpty
              ? null
              : _asString(data['kmsDriven']),
      registeredIn: (data['registeredIn'] is String)
          ? data['registeredIn'] as String
          : _asString(data['registeredIn']).isEmpty
              ? null
              : _asString(data['registeredIn']),
      name: (data['name'] is String)
          ? data['name'] as String
          : _asString(data['name']).isEmpty
              ? null
              : _asString(data['name']),
      phone: (data['phone'] is String)
          ? data['phone'] as String
          : _asString(data['phone']).isEmpty
              ? null
              : _asString(data['phone']),
      previousStatus: (data['previousStatus'] is String)
          ? data['previousStatus'] as String
          : _asString(data['previousStatus']).isEmpty
              ? null
              : _asString(data['previousStatus']),
      imageUrls: imageUrlsList,
    );
  }

  // Convert AdModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'price': price,
      'location': location,
      'year': year,
      'mileage': mileage,
      'fuel': fuel,
      'status': status,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'description': description,
      'carBrand': carBrand,
      'bodyColor': bodyColor,
      'kmsDriven': kmsDriven,
      'registeredIn': registeredIn,
      'name': name,
      'phone': phone,
      'previousStatus': previousStatus,
      'imageUrls': imageUrls,
    };
  }
}
