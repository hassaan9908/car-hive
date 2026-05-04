/// Stripe Configuration
/// 
/// This file contains Stripe publishable key and configuration
/// The secret key should NEVER be stored in the client app
class StripeConfig {
  // Stripe publishable key loaded at runtime from Firebase Realtime Database
  static String publishableKey = '';

  static void setPublishableKey(String key) {
    publishableKey = key.trim();
  }

  // Currency code
  static const String currency = 'usd';

  // Merchant identifier (for Apple Pay)
  static const String merchantIdentifier = 'merchant.com.carhive';
}

