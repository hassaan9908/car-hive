/// Stripe Configuration
/// 
/// This file contains Stripe publishable key and configuration
/// The secret key should NEVER be stored in the client app
class StripeConfig {
  // Stripe publishable key (safe to expose in client)
  static const String publishableKey = 
      'pk_test_51SgTrF06P57eoMHk2npQbiU3HeWYo9ruCZPzTx9jg0vLCgGy6q0asl5F3NsBKJB2XCOMx3cNvhnFEIiLLMLuyB2Z00EPYdmX9B';

  // Currency code
  static const String currency = 'usd';

  // Merchant identifier (for Apple Pay)
  static const String merchantIdentifier = 'merchant.com.carhive';
}

