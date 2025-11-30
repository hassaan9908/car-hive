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
  final Map<String, double>? locationCoordinates; // {lat: double, lng: double}
  final List<String>? images360Urls; // 360° view images (8 angles)

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
    this.locationCoordinates,
    this.images360Urls,
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

  // Factory constructor to create AdModel from Firestore document
  factory AdModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Parse imageUrls from Firestore
    List<String>? imageUrlsList;
    if (data['imageUrls'] != null) {
      if (data['imageUrls'] is List) {
        imageUrlsList = List<String>.from(data['imageUrls']);
      }
    }
    
    // Parse images360Urls from Firestore
    List<String>? images360UrlsList;
    if (data['images360Urls'] != null) {
      if (data['images360Urls'] is List) {
        images360UrlsList = List<String>.from(data['images360Urls']);
      }
    }
    
    // Parse location - can be string or coordinates object
    String locationString = '';
    Map<String, double>? locationCoords;
    
    if (data['locationString'] != null) {
      // New format: locationString has the text, location has coordinates
      locationString = data['locationString'] as String;
      if (data['location'] != null && data['location'] is Map) {
        final loc = data['location'] as Map<String, dynamic>;
        if (loc['lat'] != null && loc['lng'] != null) {
          locationCoords = {
            'lat': (loc['lat'] as num).toDouble(),
            'lng': (loc['lng'] as num).toDouble(),
          };
        }
      }
    } else if (data['location'] != null) {
      // Old format: location is a string, or new format without locationString
      if (data['location'] is String) {
        locationString = data['location'] as String;
      } else if (data['location'] is Map) {
        // New format: location is coordinates object
        final loc = data['location'] as Map<String, dynamic>;
        if (loc['lat'] != null && loc['lng'] != null) {
          locationCoords = {
            'lat': (loc['lat'] as num).toDouble(),
            'lng': (loc['lng'] as num).toDouble(),
          };
        }
        // Try to get locationString from elsewhere or use empty
        locationString = data['locationString'] as String? ?? '';
      }
    }
    
    return AdModel(
      id: documentId,
      title: data['title'] ?? '',
      price: data['price'] ?? '',
      location: locationString,
      year: data['year'] ?? '',
      mileage: data['mileage'] ?? '',
      fuel: data['fuel'] ?? '',
      status: data['status'] ?? 'active',
      userId: data['userId'],
      createdAt: _parseCreatedAt(data['createdAt']),
      description: data['description'],
      carBrand: data['carBrand'],
      bodyColor: data['bodyColor'],
      kmsDriven: data['kmsDriven'],
      registeredIn: data['registeredIn'],
      name: data['name'],
      phone: data['phone'],
      previousStatus: data['previousStatus'],
      imageUrls: imageUrlsList,
      locationCoordinates: locationCoords,
      images360Urls: images360UrlsList,
    );
  }

  // Convert AdModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'title': title,
      'price': price,
      'location': location, // String location for backward compatibility
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
      'images360Urls': images360Urls,
    };
    
    // Add location coordinates if available (overwrites 'location' string with coordinates object)
    if (locationCoordinates != null) {
      data['location'] = {
        'lat': locationCoordinates!['lat'],
        'lng': locationCoordinates!['lng'],
      };
      // Keep string location in a separate field for display
      data['locationString'] = location;
    }
    
    return data;
  }
}
