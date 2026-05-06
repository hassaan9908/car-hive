class BackendConfig {
  static const String _herokuBaseUrl =
      'https://carhive-360-backend-56ffd1e328e1.herokuapp.com';

  static Future<String> get baseUrl async => _herokuBaseUrl;

  static Future<String> get healthUrl async => '$_herokuBaseUrl/health';

  static Future<String> get process360Url async => '$_herokuBaseUrl/process360';
}

