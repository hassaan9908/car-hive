import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service class for handling vehicle registration API calls
/// 
/// This service makes POST requests to the vehicle registration API
/// and returns the HTML response as a string.
class VehicleService {
  // Base URL for the vehicle registration API
  // You can change this to your proxy server URL if needed
  // Example: 'https://your-proxy-server.com/api/vehicle-check'
  static const String baseUrl = 'http://58.65.189.226:8080/ovd/API_FOR_VEH_REG_DATA/VEHDATA.php';
  
  // Timeout duration (increased for proxy servers)
  static const Duration requestTimeout = Duration(seconds: 60);
  
  // Number of retry attempts
  static const int maxRetries = 2;

  /// Fetches vehicle registration data from the API with retry logic
  /// 
  /// [registrationNo] - The vehicle registration number (will be converted to uppercase)
  /// [registrationDate] - The registration date in YYYY-MM-DD format
  /// 
  /// Returns the HTML response as a string
  /// Throws an exception if the API call fails after all retries
  static Future<String> fetchVehicleData({
    required String registrationNo,
    required String registrationDate,
  }) async {
    // Convert registration number to uppercase
    final upperRegistrationNo = registrationNo.toUpperCase().trim();
    final trimmedDate = registrationDate.trim();

    // Prepare the request body with form-urlencoded data
    final body = {
      'registrationNo': upperRegistrationNo,
      'registrationDate': trimmedDate,
    };

    // Encode the body as form-urlencoded
    final encodedBody = body.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    // Retry logic
    Exception? lastException;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        // Make the POST request with increased timeout
        final response = await http.post(
          Uri.parse(baseUrl),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: encodedBody,
        ).timeout(
          requestTimeout,
          onTimeout: () {
            throw TimeoutException(
              'Request timeout after ${requestTimeout.inSeconds} seconds. '
              'The server may be slow or unreachable. '
              'If using a proxy, please check if it\'s configured correctly.',
              requestTimeout,
            );
          },
        );

        // Check if the request was successful
        if (response.statusCode == 200) {
          // Return the HTML response body
          return response.body;
        } else {
          // Throw an exception for non-200 status codes
          throw Exception(
            'API request failed with status code: ${response.statusCode}\n'
            'Response: ${response.body}',
          );
        }
      } on TimeoutException catch (e) {
        lastException = e;
        // If this is not the last attempt, wait a bit before retrying
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        }
        // Last attempt failed, format the error message
        String errorMessage = e.message ?? 'Request timeout. The server took too long to respond.';
        if (kIsWeb) {
          errorMessage += ' If using a proxy server, ensure it\'s properly configured and accessible.';
        }
        throw Exception(errorMessage);
      } on http.ClientException catch (e) {
        // Handle network errors
        String errorMessage = 'Network error: ${e.message}. Please check your internet connection.';
        
        // Check if this is a CORS error (common on web)
        if (kIsWeb && e.message.contains('Failed to fetch')) {
          errorMessage = 'CORS Error: The API server does not allow requests from web browsers. '
              'This feature works on mobile and desktop apps. Please try using the mobile app or contact the API administrator to enable CORS headers.';
        }
        
        // Retry on network errors if not the last attempt
        if (attempt < maxRetries) {
          lastException = Exception(errorMessage);
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        }
        
        throw Exception(errorMessage);
      } catch (e) {
        // Handle any other errors
        String errorMessage = e.toString();
        
        // Check for CORS errors in generic catch
        if (kIsWeb && errorMessage.contains('Failed to fetch')) {
          errorMessage = 'CORS Error: The API server does not allow requests from web browsers. '
              'This feature works on mobile and desktop apps. Please try using the mobile app or contact the API administrator to enable CORS headers.';
          throw Exception(errorMessage);
        }
        
        // Check for timeout errors
        if (errorMessage.contains('timeout') || errorMessage.contains('TimeoutException')) {
          errorMessage = 'Server timeout: The request took too long to complete. '
              'This may be due to a slow server, network issues, or proxy configuration problems. '
              'Please try again or check your proxy server settings.';
          if (attempt < maxRetries) {
            lastException = Exception(errorMessage);
            await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
            continue;
          }
          throw Exception(errorMessage);
        }
        
        // For other errors, retry only if it's a network issue
        if (attempt < maxRetries && (e.toString().contains('SocketException') || e.toString().contains('Connection'))) {
          lastException = e is Exception ? e : Exception(e.toString());
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        }
        
        // If it's an exception, rethrow it
        if (e is Exception) {
          rethrow;
        }
        throw Exception('An unexpected error occurred: $e');
      }
    }

    // If we get here, all retries failed
    throw lastException ?? Exception('Request failed after ${maxRetries + 1} attempts');
  }
}

