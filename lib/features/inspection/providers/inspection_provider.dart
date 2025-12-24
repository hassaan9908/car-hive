import 'package:flutter/material.dart';
import '../models/inspection_model.dart';
import '../services/inspection_service.dart';

class InspectionProvider extends ChangeNotifier {
  final InspectionService _inspectionService = InspectionService();

  InspectionModel? _currentInspection;
  List<InspectionModel> _userInspections = [];
  List<InspectionModel> _carInspections = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  InspectionModel? get currentInspection => _currentInspection;
  List<InspectionModel> get userInspections => _userInspections;
  List<InspectionModel> get carInspections => _carInspections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create new inspection
  InspectionModel createNewInspection({
    required String carId,
    required String carTitle,
    required String buyerId,
    required String sellerId,
  }) {
    _currentInspection = InspectionModel.createNew(
      carId: carId,
      carTitle: carTitle,
      buyerId: buyerId,
      sellerId: sellerId,
    );
    _error = null;
    notifyListeners();
    return _currentInspection!;
  }

  // Save inspection to Firestore
  Future<String> saveInspection() async {
    if (_currentInspection == null) {
      _error = 'No inspection to save';
      notifyListeners();
      return '';
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final inspectionId =
          await _inspectionService.saveInspection(_currentInspection!);
      _currentInspection!.id = inspectionId;

      _isLoading = false;
      notifyListeners();
      return inspectionId;
    } catch (e) {
      _error = 'Failed to save inspection: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update current inspection
  Future<void> updateInspection() async {
    if (_currentInspection == null || _currentInspection!.id == null) {
      _error = 'No inspection to update';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _inspectionService.updateInspection(
        _currentInspection!.id!,
        _currentInspection!,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update inspection: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Load user inspections
  Future<void> loadUserInspections() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _userInspections = await _inspectionService.getUserInspections();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load inspections: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load inspections for a specific car
  Future<void> loadCarInspections(String carId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _carInspections = await _inspectionService.getCarInspections(carId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load car inspections: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load specific inspection
  Future<void> loadInspection(String inspectionId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentInspection = await _inspectionService.getInspection(inspectionId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load inspection: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete inspection
  Future<void> deleteInspection(String inspectionId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _inspectionService.deleteInspection(inspectionId);

      _userInspections
          .removeWhere((inspection) => inspection.id == inspectionId);
      _carInspections
          .removeWhere((inspection) => inspection.id == inspectionId);

      if (_currentInspection?.id == inspectionId) {
        _currentInspection = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete inspection: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update section score
  void updateSectionScore(int sectionIndex, int rating) {
    if (_currentInspection == null ||
        sectionIndex >= _currentInspection!.sections.length) {
      return;
    }

    _currentInspection!.sections[sectionIndex].items
        .forEach((item) => item.rating = rating);
    _currentInspection!.updatedAt = DateTime.now();
    notifyListeners();
  }

  // Update item rating
  void updateItemRating(int sectionIndex, int itemIndex, int rating) {
    if (_currentInspection == null ||
        sectionIndex >= _currentInspection!.sections.length ||
        itemIndex >= _currentInspection!.sections[sectionIndex].items.length) {
      return;
    }

    _currentInspection!.sections[sectionIndex].items[itemIndex].rating = rating;
    _currentInspection!.updatedAt = DateTime.now();
    notifyListeners();
  }

  // Update item notes
  void updateItemNotes(int sectionIndex, int itemIndex, String notes) {
    if (_currentInspection == null ||
        sectionIndex >= _currentInspection!.sections.length ||
        itemIndex >= _currentInspection!.sections[sectionIndex].items.length) {
      return;
    }

    _currentInspection!.sections[sectionIndex].items[itemIndex].notes = notes;
    _currentInspection!.updatedAt = DateTime.now();
    notifyListeners();
  }

  // Add photo URL
  void addPhotoUrl(int sectionIndex, int itemIndex, String photoUrl) {
    if (_currentInspection == null ||
        sectionIndex >= _currentInspection!.sections.length ||
        itemIndex >= _currentInspection!.sections[sectionIndex].items.length) {
      return;
    }

    _currentInspection!.sections[sectionIndex].items[itemIndex].photoUrls
        .add(photoUrl);
    _currentInspection!.updatedAt = DateTime.now();
    notifyListeners();
  }

  // Remove photo URL
  void removePhotoUrl(int sectionIndex, int itemIndex, String photoUrl) {
    if (_currentInspection == null ||
        sectionIndex >= _currentInspection!.sections.length ||
        itemIndex >= _currentInspection!.sections[sectionIndex].items.length) {
      return;
    }

    _currentInspection!.sections[sectionIndex].items[itemIndex].photoUrls
        .remove(photoUrl);
    _currentInspection!.updatedAt = DateTime.now();
    notifyListeners();
  }

  // Clear current inspection
  void clearCurrentInspection() {
    _currentInspection = null;
    _error = null;
    notifyListeners();
  }
}
