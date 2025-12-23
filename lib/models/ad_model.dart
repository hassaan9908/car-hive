import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String title;
  final String price;
  final String location;
  final String year;
  final String mileage;
  final String fuel;
  late final String status;
  final String? userId;
  final String? id;
  final DateTime? createdAt;
  final String? description;
  final String? carBrand;
  final String? carName;
  final String? bodyColor;
  final String? kmsDriven;
  final String? registeredIn;
  final String? name;
  final String? phone;
  final String? previousStatus;
  final List<String>? imageUrls;
  final Map<String, double>? locationCoordinates;
  final List<String>? images360Urls;
  final DateTime? expiresAt;

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
    this.carName,
    this.bodyColor,
    this.kmsDriven,
    this.registeredIn,
    this.name,
    this.phone,
    this.previousStatus,
    this.imageUrls,
    this.locationCoordinates,
    this.images360Urls,
    this.expiresAt,
  });

  // -----------------------------
  // Helper: Parse Firestore dates
  // -----------------------------
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

  // -----------------------------
  // Helper: Convert anything → String
  // -----------------------------
  static String _asString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;

    if (value is Map) {
      final v =
          value['name'] ?? value['title'] ?? value['city'] ?? value['value'];
      if (v is String) return v;
    }
    return value.toString();
  }

  // -----------------------------
  // Helper: Extract car brand (with migration for old ads)
  // -----------------------------
  static String? _extractCarBrand(Map<String, dynamic> data) {
    final carBrand = _asString(data['carBrand']);
    final carName = _asString(data['carName']);
    
    // If carName exists, carBrand should be just the brand
    if (carName.isNotEmpty && carBrand.isNotEmpty) {
      return carBrand;
    }
    
    // Migration: If carName is empty but carBrand contains space, try to split
    if (carName.isEmpty && carBrand.isNotEmpty && carBrand.contains(' ')) {
      final parts = carBrand.trim().split(' ');
      if (parts.length >= 2) {
        // Return first part as brand (e.g., "Honda" from "Honda Civic")
        return parts[0];
      }
    }
    
    return carBrand.isEmpty ? null : carBrand;
  }

  // -----------------------------
  // Helper: Extract car name (with migration for old ads)
  // -----------------------------
  static String? _extractCarName(Map<String, dynamic> data) {
    final carName = _asString(data['carName']);
    final carBrand = _asString(data['carBrand']);
    
    // If carName exists, return it
    if (carName.isNotEmpty) {
      return carName;
    }
    
    // Migration: If carName is empty but carBrand contains space, try to split
    if (carName.isEmpty && carBrand.isNotEmpty && carBrand.contains(' ')) {
      final parts = carBrand.trim().split(' ');
      if (parts.length >= 2) {
        // Return remaining parts as name (e.g., "Civic" from "Honda Civic")
        return parts.sublist(1).join(' ');
      }
    }
    
    return carName.isEmpty ? null : null;
  }

  // -----------------------------
  // Helper: Parse image URLs
  // -----------------------------
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
          if (url is String && url.isNotEmpty) {
            out.add(url);
          }
        }
      }

      return out.isEmpty ? null : out;
    }

    // Fallback: single string
    if (raw is String && raw.isNotEmpty) return [raw];

    return null;
  }

  // ---------------------------------------------------
  // FACTORY: Convert Firestore document → AdModel object
  // ---------------------------------------------------
  factory AdModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Parse image URLs
    final imageUrlsList = _parseImageUrls(
      data['imageUrls'] ?? data['images'] ?? data['photos'],
    );

    // Parse 360° images
    List<String>? images360UrlsList;
    if (data['images360Urls'] != null && data['images360Urls'] is List) {
      images360UrlsList = List<String>.from(data['images360Urls']);
    }

    // Parse location (string + coords)
    String locationString = '';
    Map<String, double>? locationCoords;

    // First, try to parse location coordinates from 'location' field
      if (data['location'] != null && data['location'] is Map) {
        final loc = data['location'] as Map<String, dynamic>;
        if (loc['lat'] != null && loc['lng'] != null) {
        try {
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          
          // Validate coordinates are within valid ranges
          if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
          locationCoords = {
              'lat': lat,
              'lng': lng,
            };
          } else {
            print('Invalid coordinates in ad $documentId: lat=$lat, lng=$lng');
          }
        } catch (e) {
          print('Error parsing coordinates for ad $documentId: $e');
        }
      }
    }

    // Then parse location string
    if (data['locationString'] != null) {
      // New format - locationString exists
      locationString = data['locationString'] as String;
    } else if (data['location'] != null) {
      // Old format - location might be a string
      if (data['location'] is String) {
        locationString = data['location'] as String;
      } else if (locationString.isEmpty && locationCoords != null) {
        // If we have coordinates but no string, use empty string
        locationString = '';
      }
    }

    return AdModel(
      id: documentId,
      title: _asString(data['title']),
      price: _asString(data['price']),
      location: locationString,
      year: _asString(data['year']),
      mileage: _asString(data['mileage']),
      fuel: _asString(data['fuel']),
      status:
          _asString(data['status']).isEmpty ? 'active' : _asString(data['status']),
      userId:
          _asString(data['userId']).isEmpty ? null : _asString(data['userId']),
      createdAt: _parseCreatedAt(data['createdAt'] ?? data['created_at']),
      description:
          _asString(data['description']).isEmpty ? null : _asString(data['description']),
      carBrand: _extractCarBrand(data),
      carName: _extractCarName(data),
      bodyColor:
          _asString(data['bodyColor']).isEmpty ? null : _asString(data['bodyColor']),
      kmsDriven:
          _asString(data['kmsDriven']).isEmpty ? null : _asString(data['kmsDriven']),
      registeredIn:
          _asString(data['registeredIn']).isEmpty ? null : _asString(data['registeredIn']),
      name: _asString(data['name']).isEmpty ? null : _asString(data['name']),
      phone: _asString(data['phone']).isEmpty ? null : _asString(data['phone']),
      previousStatus: _asString(data['previousStatus']).isEmpty
          ? null
          : _asString(data['previousStatus']),
      imageUrls: imageUrlsList,
      locationCoordinates: locationCoords,
      images360Urls: images360UrlsList,
      expiresAt: _parseCreatedAt(data['expiresAt']),
    );
  }

  // --------------------------------------
  // Convert AdModel → Firestore map
  // --------------------------------------
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
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
      'carName': carName,
      'bodyColor': bodyColor,
      'kmsDriven': kmsDriven,
      'registeredIn': registeredIn,
      'name': name,
      'phone': phone,
      'previousStatus': previousStatus,
      'imageUrls': imageUrls,
      'images360Urls': images360Urls,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };

    if (locationCoordinates != null) {
      data['location'] = {
        'lat': locationCoordinates!['lat'],
        'lng': locationCoordinates!['lng'],
      };
      data['locationString'] = location;
    }

    return data;
  }
}
