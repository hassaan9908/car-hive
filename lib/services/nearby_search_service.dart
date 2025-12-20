import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad_model.dart';

class NearbySearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Haversine formula to calculate distance between two coordinates
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  // Calculate bounding box for latitude filtering
  Map<String, double> _calculateBoundingBox(
    double centerLat,
    double centerLng,
    double radiusKm,
  ) {
    // Approximate: 1 degree latitude ≈ 111 km
    final double latDelta = radiusKm / 111.0;
    final double lngDelta = radiusKm / (111.0 * math.cos(_degreesToRadians(centerLat)));

    return {
      'minLat': centerLat - latDelta,
      'maxLat': centerLat + latDelta,
      'minLng': centerLng - lngDelta,
      'maxLng': centerLng + lngDelta,
    };
  }

  // Search for nearby listings within radius
  Future<List<AdModel>> searchNearby({
    required double userLat,
    required double userLng,
    required double radiusKm,
  }) async {
    try {
      // Calculate bounding box
      final boundingBox = _calculateBoundingBox(userLat, userLng, radiusKm);

      // Query Firestore by latitude range only (avoid composite index requirement)
      // We'll filter by status and longitude in memory
      final querySnapshot = await _firestore
          .collection('ads')
          .where('location.lat', isGreaterThanOrEqualTo: boundingBox['minLat'])
          .where('location.lat', isLessThanOrEqualTo: boundingBox['maxLat'])
          .get();

      // Filter by status, longitude manually and calculate distance
      final List<AdModel> nearbyAds = [];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Filter by status (active only)
        if (data['status'] != 'active') continue;
        
        // Check if location exists
        if (data['location'] == null) continue;
        
        // Check if location is an object (not a string)
        if (data['location'] is! Map) continue;

        final location = data['location'] as Map<String, dynamic>;
        if (location['lat'] == null || location['lng'] == null) continue;
        
        final adLat = (location['lat'] as num).toDouble();
        final adLng = (location['lng'] as num).toDouble();

        // Filter by longitude
        if (adLng < boundingBox['minLng']! || adLng > boundingBox['maxLng']!) {
          continue;
        }

        // Validate coordinates before calculating distance
        if (adLat < -90 || adLat > 90 || adLng < -180 || adLng > 180) {
          print('Invalid coordinates for ad ${doc.id}: lat=$adLat, lng=$adLng');
          continue;
        }

        // Calculate actual distance using Haversine formula
        final distance = _calculateDistance(userLat, userLng, adLat, adLng);

        // Only include if within radius
        if (distance <= radiusKm) {
          final ad = AdModel.fromFirestore(data, doc.id);
          // Verify locationCoordinates were properly parsed
          if (ad.locationCoordinates == null) {
            print('Warning: Ad ${doc.id} has location in Firestore but locationCoordinates is null after parsing');
            // Skip this ad as it won't display correctly on map
            continue;
          }
          nearbyAds.add(ad);
        }
      }

      return nearbyAds;
    } catch (e) {
      print('Error searching nearby: $e');
      return [];
    }
  }

  // Stream version for real-time updates
  Stream<List<AdModel>> streamNearby({
    required double userLat,
    required double userLng,
    required double radiusKm,
  }) {
    // Calculate bounding box
    final boundingBox = _calculateBoundingBox(userLat, userLng, radiusKm);

    return _firestore
        .collection('ads')
        .where('location.lat', isGreaterThanOrEqualTo: boundingBox['minLat'])
        .where('location.lat', isLessThanOrEqualTo: boundingBox['maxLat'])
        .snapshots()
        .map((snapshot) {
      final List<AdModel> nearbyAds = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Filter by status (active only)
        if (data['status'] != 'active') continue;
        
        // Check if location exists and is an object
        if (data['location'] == null || data['location'] is! Map) continue;

        final location = data['location'] as Map<String, dynamic>;
        if (location['lat'] == null || location['lng'] == null) continue;
        
        final adLat = (location['lat'] as num).toDouble();
        final adLng = (location['lng'] as num).toDouble();

        // Filter by longitude
        if (adLng < boundingBox['minLng']! || adLng > boundingBox['maxLng']!) {
          continue;
        }

        // Validate coordinates before calculating distance
        if (adLat < -90 || adLat > 90 || adLng < -180 || adLng > 180) {
          print('Invalid coordinates for ad ${doc.id}: lat=$adLat, lng=$adLng');
          continue;
        }

        // Calculate actual distance using Haversine formula
        final distance = _calculateDistance(userLat, userLng, adLat, adLng);

        // Only include if within radius
        if (distance <= radiusKm) {
          final ad = AdModel.fromFirestore(data, doc.id);
          // Verify locationCoordinates were properly parsed
          if (ad.locationCoordinates == null) {
            print('Warning: Ad ${doc.id} has location in Firestore but locationCoordinates is null after parsing');
            // Skip this ad as it won't display correctly on map
            continue;
          }
          nearbyAds.add(ad);
        }
      }

      return nearbyAds;
    });
  }
}

