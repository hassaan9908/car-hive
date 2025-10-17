import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  AuthProvider() {
    _initAuthState();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  void _initAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user =
          await _authService.loginUserWithEmailAndPassword(email, password);
      _user = user;
      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password, {
    String? fullName,
    String? username,
    String? birthday,
    String? gender,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.createUserWithEmailAndPassword(
        email,
        password,
        fullName: fullName,
        username: username,
        birthday: birthday,
        gender: gender,
      );
      _user = user;
      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        _user = result.user;
        return result.user;
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signout();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getDisplayName() {
    if (_user == null) return '';

    // Try to get display name from Firebase user
    if (_user!.displayName != null && _user!.displayName!.isNotEmpty) {
      return _user!.displayName!;
    }

    // Fallback to email (remove domain part)
    if (_user!.email != null) {
      String email = _user!.email!;
      return email.split('@')[0];
    }

    return 'User';
  }

  String getEmail() {
    return _user?.email ?? '';
  }

  Future<String> getUsername() async {
    if (_user == null) return '';
    
    try {
      final userDoc = await _authService.getUserDocument(_user!.uid);
      
      if (userDoc != null) {
        final username = userDoc['username'] as String?;
        return username ?? '';
      }
    } catch (e) {
      print('Error getting username: $e');
    }
    
    return '';
  }
}
