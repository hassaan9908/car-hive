import 'package:flutter/material.dart';
import 'package:carhive/models/ad_model.dart';
import 'package:carhive/store/global_ads.dart';
import 'package:carhive/services/car_brand_service.dart';

class SearchProvider extends ChangeNotifier {
  String _searchQuery = '';
  String? _selectedBrandId;
  List<AdModel> _allAds = [];
  List<AdModel> _filteredAds = [];
  bool _isLoading = false;
  String? _error;

  String get searchQuery => _searchQuery;
  String? get selectedBrandId => _selectedBrandId;
  List<AdModel> get filteredAds => _filteredAds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize with all ads
  Future<void> initializeAds() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final globalAdStore = GlobalAdStore();
      final adsStream = globalAdStore.getAllActiveAds();
      
      await for (List<AdModel> ads in adsStream) {
        _allAds = ads;
        _filteredAds = ads;
        _isLoading = false;
        notifyListeners();
        break; // Get the first snapshot
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update search query and filter ads
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _filterAds();
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _filterAds();
    notifyListeners();
  }

  // Set brand filter
  void setBrandFilter(String? brandId) {
    _selectedBrandId = brandId;
    _filterAds();
    notifyListeners();
  }

  // Clear brand filter
  void clearBrandFilter() {
    _selectedBrandId = null;
    _filterAds();
    notifyListeners();
  }

  // Filter ads based on search query and brand
  void _filterAds() {
    var filtered = _allAds;

    // Apply brand filter first
    if (_selectedBrandId != null && _selectedBrandId!.isNotEmpty) {
      final brandService = CarBrandService();
      final brand = brandService.getBrandById(_selectedBrandId!);
      final brandName = brand?.displayName ?? _selectedBrandId!;
      
      filtered = filtered.where((ad) {
        if (ad.carBrand == null) return false;
        final adBrandLower = ad.carBrand!.toLowerCase();
        final selectedBrandLower = brandName.toLowerCase();
        return adBrandLower == selectedBrandLower ||
            adBrandLower.contains(selectedBrandLower) ||
            selectedBrandLower.contains(adBrandLower);
      }).toList();
    }

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((ad) {
        // Search by brand name
        if (ad.carBrand != null && ad.carBrand!.toLowerCase().contains(query)) {
          return true;
        }
        
        // Search by car name
        if (ad.carName != null && ad.carName!.toLowerCase().contains(query)) {
          return true;
        }
        
        // Search by title
        if (ad.title.toLowerCase().contains(query)) {
          return true;
        }
        
        // Search by location
        if (ad.location.toLowerCase().contains(query)) {
          return true;
        }
        
        // Search by year
        if (ad.year.toLowerCase().contains(query)) {
          return true;
        }
        
        // Search by fuel type
        if (ad.fuel.toLowerCase().contains(query)) {
          return true;
        }
        
        return false;
      }).toList();
    }

    _filteredAds = filtered;
  }

  // Get search suggestions based on available brands
  List<String> getSearchSuggestions() {
    if (_searchQuery.isEmpty) return [];
    
    final query = _searchQuery.toLowerCase().trim();
    final suggestions = <String>{};
    
    for (final ad in _allAds) {
      if (ad.carBrand != null && ad.carBrand!.isNotEmpty) {
        final brand = ad.carBrand!;
        if (brand.toLowerCase().contains(query)) {
          suggestions.add(brand);
        }
      }
    }
    
    return suggestions.toList()..sort();
  }

  // Check if search has results
  bool get hasSearchResults => _filteredAds.isNotEmpty;
  
  // Check if search is active
  bool get isSearchActive => _searchQuery.isNotEmpty;
}
