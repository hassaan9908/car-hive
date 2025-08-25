// Web-only configuration for CarHive Admin Panel
// This file ensures the admin panel only works on web platforms

import 'package:flutter/foundation.dart';

class AdminWebConfig {
  static bool get isWebOnly => kIsWeb;
  
  static void ensureWebPlatform() {
    if (!kIsWeb) {
      throw UnsupportedError(
        'CarHive Admin Panel is only available on web platforms. '
        'Please access the admin panel through a web browser.'
      );
    }
  }
  
  static String get platformMessage => kIsWeb 
    ? 'Web Platform Detected - Admin Panel Available'
    : 'Mobile Platform Detected - Admin Panel Not Available';
}


