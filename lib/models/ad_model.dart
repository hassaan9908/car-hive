import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String title;
  final String price;
  final String location;
  final String year;
  final String mileage;
  final String fuel;
  late final String status; // 'active', 'pending', 'removed'
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
    return AdModel(
      id: documentId,
      title: data['title'] ?? '',
      price: data['price'] ?? '',
      location: data['location'] ?? '',
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
    };
  }
}