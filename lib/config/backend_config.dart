import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration for 360° video processing backend
/// 
/// For physical devices, users can configure the backend URL in the app.
/// The URL is stored in SharedPreferences and persists across app restarts.
class BackendConfig {
  static const String _prefsKeyBackendUrl = 'backend_360_url';
  
  /// Backend base URL
  /// 
  /// For web/emulator: uses localhost
  /// For physical devices: uses stored URL or prompts user to configure
  /// 
  /// To find your IP:
  /// - Windows: Run `ipconfig` and look for "IPv4 Address"
  /// - macOS/Linux: Run `ifconfig` or `ip addr` and look for your network interface
  /// 
  /// Example: 'http://192.168.1.100:8000'
  static Future<String> get baseUrl async {
    if (kIsWeb) {
      // Web: use localhost
      return 'http://localhost:8000';
    } else {
      // Mobile: Check if custom URL is stored
      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString(_prefsKeyBackendUrl);
      
      if (customUrl != null && customUrl.isNotEmpty) {
        return customUrl;
      }
      
      // Default: Android emulator uses 10.0.2.2 to access host machine
      // For physical devices, this won't work - user needs to configure
      return 'http://10.0.2.2:8000';
    }
  }
  
  /// Set custom backend URL (for physical devices)
  static Future<void> setCustomBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyBackendUrl, url);
  }
  
  /// Get stored backend URL (returns null if not set)
  static Future<String?> getStoredBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyBackendUrl);
  }
  
  /// Clear stored backend URL (reset to default)
  static Future<void> clearCustomBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyBackendUrl);
  }
  
  /// Backend port
  static const int port = 8000;
  
  /// Health check endpoint
  static Future<String> get healthUrl async => '${await baseUrl}/health';
  
  /// Process 360 video endpoint
  static Future<String> get process360Url async => '${await baseUrl}/process360';
}

