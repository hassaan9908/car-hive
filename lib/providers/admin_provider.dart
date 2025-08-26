import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/ad_model.dart';
import '../models/admin_stats_model.dart';
import '../models/activity_model.dart';
import '../services/admin_service.dart';
import '../services/admin_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  final AdminAuthService _adminAuthService = AdminAuthService();

  // State variables
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  AdminStatsModel? _dashboardStats;
  List<UserModel> _users = [];
  List<AdModel> _pendingAds = [];
  List<ActivityModel> _recentActivities = [];
  UserModel? _currentAdmin;

  AdminProvider() {
    // Listen to Firebase Auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        print('AdminProvider: Firebase Auth state changed, user logged in: ${user.email}');
        // Wait a bit for the user to be fully loaded
        Future.delayed(const Duration(milliseconds: 100), () {
          refreshOnAuthChange();
        });
      } else {
        print('AdminProvider: Firebase Auth state changed, user logged out');
        _isAuthenticated = false;
        _clearData();
        notifyListeners();
      }
    });
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  AdminStatsModel? get dashboardStats => _dashboardStats;
  List<UserModel> get users => _users;
  List<AdModel> get pendingAds => _pendingAds;
  List<ActivityModel> get recentActivities => _recentActivities;
  UserModel? get currentAdmin => _currentAdmin;
  
  // Check if current user has admin privileges
  bool get hasAdminPrivileges {
    if (_currentAdmin == null) return false;
    return _currentAdmin!.role == 'admin' || _currentAdmin!.role == 'super_admin';
  }
  
  // Get current user role
  String get currentUserRole => _currentAdmin?.role ?? 'none';
  
  // Force refresh admin status
  Future<void> refreshAdminStatus() async {
    await initialize();
  }
  
  // Reset admin provider state (useful for testing)
  void resetState() {
    _isLoading = false;
    _isAuthenticated = false;
    _errorMessage = null;
    _clearData();
    notifyListeners();
  }
  
  // Check if current user can access admin panel
  bool get canAccessAdminPanel {
    if (!_isAuthenticated || _currentAdmin == null) return false;
    return _currentAdmin!.role == 'admin' || _currentAdmin!.role == 'super_admin';
  }
  
  // Manual refresh when auth state changes
  Future<void> refreshOnAuthChange() async {
    print('AdminProvider: Auth state changed, refreshing admin status...');
    await initialize();
  }

  // Initialize admin provider
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();
      
      print('AdminProvider: Starting initialization...');
      
      // Check if user is currently signed in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('AdminProvider: No user signed in');
        _isAuthenticated = false;
        _clearData();
        return;
      }
      
      print('AdminProvider: Current user: ${currentUser.email} (${currentUser.uid})');
      
      // Check if user has admin role
      final isAdmin = await _adminAuthService.isCurrentUserAdmin();
      
      print('AdminProvider: isCurrentUserAdmin() returned: $isAdmin');
      
      if (isAdmin) {
        // User is an admin, authenticate them
        _isAuthenticated = true;
        print('AdminProvider: User is admin, loading data...');
        
        await _loadCurrentAdminData();
        
        print('AdminProvider: Current admin loaded: ${_currentAdmin?.role}');
        
        // Double-check that the loaded user actually has admin role
        if (_currentAdmin != null && 
            (_currentAdmin!.role == 'admin' || _currentAdmin!.role == 'super_admin')) {
          print('AdminProvider: Role verified, loading dashboard stats...');
          await _loadDashboardStats();
          print('AdminProvider: Initialization complete for admin user');
        } else {
          // User doesn't actually have admin role, deny access
          print('AdminProvider: Role verification failed, denying access');
          _isAuthenticated = false;
          _clearData();
        }
      } else {
        // User is not an admin, deny access
        print('AdminProvider: User is not admin, denying access');
        _isAuthenticated = false;
        _clearData();
      }
    } catch (e) {
      print('AdminProvider: Error during initialization: $e');
      _setError('Failed to initialize admin panel: $e');
      _isAuthenticated = false;
      _clearData();
    } finally {
      _setLoading(false);
      print('AdminProvider: Initialization finished. isAuthenticated: $_isAuthenticated, role: ${_currentAdmin?.role}');
      debugCurrentState();
    }
  }

  // Admin login
  Future<bool> adminLogin(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _adminAuthService.adminLogin(email, password);
      _isAuthenticated = true;
      
      await _loadDashboardStats();
      await _loadCurrentAdminData();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Admin logout
  Future<void> adminLogout() async {
    try {
      print('AdminProvider: Admin logout requested');
      _isAuthenticated = false;
      _clearData();
      notifyListeners();
      print('AdminProvider: Admin logout completed');
    } catch (e) {
      print('AdminProvider: Error during admin logout: $e');
      _setError('Logout failed: $e');
    }
  }

  // Load dashboard statistics
  Future<void> loadDashboardStats() async {
    try {
      _setLoading(true);
      await _loadDashboardStats();
    } catch (e) {
      _setError('Failed to load dashboard stats: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load recent activities
  Future<void> loadRecentActivities({int limit = 10}) async {
    try {
      _setLoading(true);
      _recentActivities = await _adminService.getRecentActivities(limit: limit);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recent activities: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load users
  Future<void> loadUsers({int limit = 20}) async {
    try {
      _setLoading(true);
      _users = await _adminService.getUsers(limit: limit);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load users: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load pending ads
  Future<void> loadPendingAds({int limit = 20}) async {
    try {
      print('AdminProvider: Loading pending ads...');
      _setLoading(true);
      _pendingAds = await _adminService.getPendingAds(limit: limit);
      print('AdminProvider: Loaded ${_pendingAds.length} pending ads');
      for (var ad in _pendingAds) {
        print('AdminProvider: Pending ad - ${ad.title} (${ad.id})');
      }
      notifyListeners();
    } catch (e) {
      print('AdminProvider: Error loading pending ads: $e');
      _setError('Failed to load pending ads: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Approve ad
  Future<bool> approveAd(String adId) async {
    try {
      _setLoading(true);
      await _adminService.approveAd(adId);
      
      // Remove from pending ads and update stats
      _pendingAds.removeWhere((ad) => ad.id == adId);
      await _loadDashboardStats();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to approve ad: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reject ad
  Future<bool> rejectAd(String adId, String reason) async {
    try {
      _setLoading(true);
      await _adminService.rejectAd(adId, reason);
      
      // Remove from pending ads and update stats
      _pendingAds.removeWhere((ad) => ad.id == adId);
      await _loadDashboardStats();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to reject ad: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user role
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      _setLoading(true);
      await _adminService.updateUserRole(userId, newRole);
      
      // Update local user list
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(role: newRole);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to update user role: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle user status
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      _setLoading(true);
      await _adminService.toggleUserStatus(userId, isActive);
      
      // Update local user list
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(isActive: isActive);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to toggle user status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      return await _adminService.searchUsers(query);
    } catch (e) {
      _setError('Search failed: $e');
      return [];
    }
  }

  // Search ads
  Future<List<AdModel>> searchAds(String query) async {
    try {
      return await _adminService.searchAds(query);
    } catch (e) {
      _setError('Search failed: $e');
      return [];
    }
  }

  // Debug method to check and fix ad statuses
  Future<void> debugAndFixAdStatuses() async {
    try {
      print('AdminProvider: Debugging ad statuses...');
      await _adminService.debugAndFixAdStatuses();
      // Reload pending ads after fixing
      await loadPendingAds();
    } catch (e) {
      print('AdminProvider: Error debugging ad statuses: $e');
      _setError('Debug failed: $e');
    }
  }

  // Debug method to check current state
  void debugCurrentState() {
    print('=== AdminProvider Debug State ===');
    print('isLoading: $_isLoading');
    print('isAuthenticated: $_isAuthenticated');
    print('errorMessage: $_errorMessage');
    print('currentAdmin: ${_currentAdmin?.email} (${_currentAdmin?.role})');
    print('hasAdminPrivileges: $hasAdminPrivileges');
    print('canAccessAdminPanel: $canAccessAdminPanel');
    print('currentUserRole: $currentUserRole');
    print('Firebase current user: ${FirebaseAuth.instance.currentUser?.email}');
    print('================================');
  }

  // Private helper methods
  Future<void> _loadDashboardStats() async {
    _dashboardStats = await _adminService.getDashboardStats();
  }

  Future<void> _loadCurrentAdminData() async {
    try {
      print('AdminProvider: Loading current admin data...');
      final adminData = await _adminAuthService.getCurrentAdminData();
      if (adminData != null) {
        // Get the current user's UID from Firebase Auth
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          print('AdminProvider: Creating UserModel from admin data...');
          _currentAdmin = UserModel.fromFirestore(adminData, currentUser.uid);
          print('AdminProvider: UserModel created successfully. Role: ${_currentAdmin?.role}');
        } else {
          print('AdminProvider: No current user found when loading admin data');
        }
      } else {
        print('AdminProvider: No admin data returned from getCurrentAdminData()');
      }
    } catch (e) {
      print('AdminProvider: Error loading current admin data: $e');
      _currentAdmin = null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _clearData() {
    _dashboardStats = null;
    _users.clear();
    _pendingAds.clear();
    _recentActivities.clear();
    _currentAdmin = null;
  }
}
