import 'package:flutter/material.dart';
import 'package:carhive/models/ad_model.dart';
import 'package:carhive/store/global_ads.dart';

class SearchProvider extends ChangeNotifier {
  String _searchQuery = '';
  List<AdModel> _allAds = [];
  List<AdModel> _filteredAds = [];
  bool _isLoading = false;
  String? _error;

  String get searchQuery => _searchQuery;
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
    _filteredAds = _allAds;
    notifyListeners();
  }

  // Filter ads based on search query
  void _filterAds() {
    if (_searchQuery.isEmpty) {
      _filteredAds = _allAds;
      return;
    }

    final query = _searchQuery.toLowerCase().trim();
    _filteredAds = _allAds.where((ad) {
      // Search by brand name (primary search)
      if (ad.carBrand != null && ad.carBrand!.toLowerCase().contains(query)) {
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
