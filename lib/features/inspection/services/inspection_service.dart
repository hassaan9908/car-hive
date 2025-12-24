import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inspection_model.dart';
import '../models/inspection_section_model.dart';
import '../models/inspection_item_model.dart';

class InspectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save inspection to separate inspections collection
  Future<String> saveInspectionReport(InspectionModel inspection) async {
    try {
      final userId = await _ensureSignedIn();
      final currentUser = _auth.currentUser;

      print('\n=== SAVE INSPECTION REPORT ===');
      print('userId: $userId');
      print('currentUser.uid: ${currentUser?.uid}');
      print('Firestore rule requires: userId == currentUid()');

      final docRef = await _firestore.collection('inspections').add({
        'userId': userId,
        'carId': inspection.carId,
        'carTitle': inspection.carTitle,
        'buyerId': inspection.buyerId,
        'sellerId': inspection.sellerId,
        'status': inspection.status,
        'overallScore': inspection.overallScore,
        'completedItems': inspection.completedItems,
        'totalItems': inspection.totalItems,
        'progress': inspection.progress,
        'createdAt': inspection.createdAt,
        'updatedAt': inspection.updatedAt,
        'savedAt': DateTime.now(),
        'sections': inspection.sections
            .map((section) => {
                  'id': section.id,
                  'name': section.name,
                  'icon': section.icon,
                  'completedCount': section.completedCount,
                  'totalCount': section.totalCount,
                  'items': section.items
                      .map((item) => {
                            'id': item.id,
                            'question': item.question,
                            'category': item.category,
                            'rating': item.rating,
                            'notes': item.notes,
                            'photoUrls': item.photoUrls,
                          })
                      .toList(),
                })
            .toList(),
      });

      print('✓ SUCCESS: Inspection saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('\n✗ ERROR saving inspection report');
      print('Error message: $e');
      print('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      rethrow;
    }
  }

  // Save inspection to Firestore
  Future<String> saveInspection(InspectionModel inspection) async {
    try {
      final userId = await _ensureSignedIn();

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('inspections')
          .add({
        'carId': inspection.carId,
        'carTitle': inspection.carTitle,
        'buyerId': inspection.buyerId,
        'sellerId': inspection.sellerId,
        'status': inspection.status,
        'overallScore': inspection.overallScore,
        'completedItems': inspection.completedItems,
        'totalItems': inspection.totalItems,
        'progress': inspection.progress,
        'createdAt': inspection.createdAt,
        'updatedAt': inspection.updatedAt,
        'sections': inspection.sections
            .map((section) => {
                  'id': section.id,
                  'name': section.name,
                  'icon': section.icon,
                  'completedCount': section.completedCount,
                  'totalCount': section.totalCount,
                  'items': section.items
                      .map((item) => {
                            'id': item.id,
                            'question': item.question,
                            'category': item.category,
                            'rating': item.rating,
                            'notes': item.notes,
                            'photoUrls': item.photoUrls,
                          })
                      .toList(),
                })
            .toList(),
      });

      return docRef.id;
    } catch (e) {
      print('Error saving inspection: $e');
      rethrow;
    }
  }

  // Update inspection in Firestore
  Future<void> updateInspection(
      String inspectionId, InspectionModel inspection) async {
    try {
      final userId = await _ensureSignedIn();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('inspections')
          .doc(inspectionId)
          .update({
        'overallScore': inspection.overallScore,
        'completedItems': inspection.completedItems,
        'progress': inspection.progress,
        'updatedAt': inspection.updatedAt,
        'sections': inspection.sections
            .map((section) => {
                  'id': section.id,
                  'name': section.name,
                  'icon': section.icon,
                  'completedCount': section.completedCount,
                  'totalCount': section.totalCount,
                  'items': section.items
                      .map((item) => {
                            'id': item.id,
                            'question': item.question,
                            'category': item.category,
                            'rating': item.rating,
                            'notes': item.notes,
                            'photoUrls': item.photoUrls,
                          })
                      .toList(),
                })
            .toList(),
      });
    } catch (e) {
      print('Error updating inspection: $e');
      rethrow;
    }
  }

  // Get inspection by ID
  Future<InspectionModel?> getInspection(String inspectionId) async {
    try {
      final userId = await _ensureSignedIn();

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('inspections')
          .doc(inspectionId)
          .get();

      if (doc.exists) {
        return _inspectionFromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting inspection: $e');
      rethrow;
    }
  }

  // Get all inspections for current user
  Future<List<InspectionModel>> getUserInspections() async {
    try {
      final userId = await _ensureSignedIn();

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('inspections')
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => _inspectionFromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user inspections: $e');
      rethrow;
    }
  }

  // Get inspections for a specific car
  Future<List<InspectionModel>> getCarInspections(String carId) async {
    try {
      final userId = await _ensureSignedIn();

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('inspections')
          .where('carId', isEqualTo: carId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => _inspectionFromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting car inspections: $e');
      rethrow;
    }
  }

  // Delete inspection
  Future<void> deleteInspection(String inspectionId) async {
    try {
      final userId = await _ensureSignedIn();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('inspections')
          .doc(inspectionId)
          .delete();
    } catch (e) {
      print('Error deleting inspection: $e');
      rethrow;
    }
  }

  // Stream inspections for a car
  Stream<List<InspectionModel>> streamCarInspections(String carId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('inspections')
        .where('carId', isEqualTo: carId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _inspectionFromFirestore(doc)).toList());
  }

  // Helper function to convert Firestore document to InspectionModel
  InspectionModel _inspectionFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Build sections and items immutably
    final sectionsData = (data['sections'] as List<dynamic>? ?? []);
    final List<InspectionSection> sections =
        sectionsData.map<InspectionSection>((sectionData) {
      final itemsData = (sectionData['items'] as List<dynamic>? ?? []);
      final List<InspectionItem> items =
          itemsData.map<InspectionItem>((itemData) {
        return InspectionItem(
          id: itemData['id'] ?? '',
          question: itemData['question'] ?? '',
          category: itemData['category'] ?? '',
          rating: itemData['rating'] ?? -1,
          notes: itemData['notes'] ?? '',
          photoUrls: List<String>.from(itemData['photoUrls'] ?? []),
        );
      }).toList();

      return InspectionSection(
        id: sectionData['id'] ?? '',
        name: sectionData['name'] ?? '',
        icon: sectionData['icon'] ?? '',
        items: items,
      );
    }).toList();

    return InspectionModel(
      id: doc.id,
      carId: data['carId'] ?? '',
      carTitle: data['carTitle'] ?? '',
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sections: sections,
      status: data['status'] ?? 'in_progress',
    );
  }

  // Ensure user is signed in; if not, throw error
  Future<String> _ensureSignedIn() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated. Please sign in first.');
    }
    return user.uid;
  }
}
