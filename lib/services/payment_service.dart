import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/stripe_config.dart';
import 'currency_converter_service.dart';

/// Payment Service for handling payment gateway integrations
/// 
/// This service provides a unified interface for processing payments
/// through various payment methods (JazzCash, EasyPay, Bank Transfer, Stripe)
class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Payment gateway configuration
  // TODO: Add actual API keys and configuration
  // These will be used when integrating with actual payment gateways
  // ignore: unused_field
  static const String _jazzCashApiKey = 'YOUR_JAZZCASH_API_KEY';
  // ignore: unused_field
  static const String _easyPayApiKey = 'YOUR_EASYPAY_API_KEY';

  /// Process payment through the selected payment method
  /// 
  /// Returns a map with:
  /// - 'success': bool indicating if payment was successful
  /// - 'reference': String transaction reference number
  /// - 'error': String error message if payment failed
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String paymentMethod,
    required String transactionId,
    String? description,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Validate inputs
      if (amount <= 0) {
        return {
          'success': false,
          'error': 'Invalid payment amount',
        };
      }

      if (paymentMethod.isEmpty) {
        return {
          'success': false,
          'error': 'Payment method not specified',
        };
      }

      // Route to appropriate payment processor
      switch (paymentMethod.toLowerCase()) {
        case 'jazzcash':
          return await _processJazzCashPayment(
            amount: amount,
            transactionId: transactionId,
            description: description,
          );

        case 'easypay':
          return await _processEasyPayPayment(
            amount: amount,
            transactionId: transactionId,
            description: description,
          );

        case 'bank_transfer':
          return await _processBankTransfer(
            amount: amount,
            transactionId: transactionId,
            description: description,
          );

        case 'card':
        case 'stripe':
          return await _processStripePayment(
            amount: amount,
            transactionId: transactionId,
            description: description,
            additionalData: additionalData,
          );

        default:
          return {
            'success': false,
            'error': 'Unsupported payment method',
          };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Payment processing error: $e',
      };
    }
  }

  /// Process payment through JazzCash
  /// 
  /// TODO: Integrate with JazzCash API
  Future<Map<String, dynamic>> _processJazzCashPayment({
    required double amount,
    required String transactionId,
    String? description,
  }) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Replace with actual JazzCash API integration
    // Example integration:
    // final response = await http.post(
    //   Uri.parse('https://api.jazzcash.com.pk/payment'),
    //   headers: {
    //     'Authorization': 'Bearer $_jazzCashApiKey',
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode({
    //     'amount': amount,
    //     'transactionId': transactionId,
    //     'description': description,
    //   }),
    // );
    // 
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   return {
    //     'success': true,
    //     'reference': data['transactionReference'],
    //   };
    // }

    // For now, simulate successful payment
    // In production, this should call the actual API
    return {
      'success': true,
      'reference': 'JC${DateTime.now().millisecondsSinceEpoch}',
      'message': 'Payment processed successfully (Simulated)',
    };
  }

  /// Process payment through EasyPay
  /// 
  /// TODO: Integrate with EasyPay API
  Future<Map<String, dynamic>> _processEasyPayPayment({
    required double amount,
    required String transactionId,
    String? description,
  }) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Replace with actual EasyPay API integration
    // For now, simulate successful payment
    return {
      'success': true,
      'reference': 'EP${DateTime.now().millisecondsSinceEpoch}',
      'message': 'Payment processed successfully (Simulated)',
    };
  }

  /// Process bank transfer
  /// 
  /// This typically involves generating payment instructions
  /// and waiting for manual confirmation
  Future<Map<String, dynamic>> _processBankTransfer({
    required double amount,
    required String transactionId,
    String? description,
  }) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 1));

    // Bank transfers usually require manual verification
    // For now, we'll simulate automatic approval
    // In production, this should:
    // 1. Generate payment instructions
    // 2. Send to user
    // 3. Wait for admin confirmation
    // 4. Update transaction status

    return {
      'success': true,
      'reference': 'BT${DateTime.now().millisecondsSinceEpoch}',
      'message': 'Bank transfer initiated (Requires manual verification)',
    };
  }

  /// Process Stripe payment (Debit/Credit Card)
  /// 
  /// Creates a payment intent via Cloud Function and presents Stripe payment sheet
  /// For web: Uses Stripe Checkout redirect
  /// For mobile: Uses native payment sheet
  Future<Map<String, dynamic>> _processStripePayment({
    required double amount,
    required String transactionId,
    String? description,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      // Convert PKR to USD for Stripe (Stripe doesn't support PKR)
      // Amount is in PKR, but Stripe requires USD
      final amountInUsd = CurrencyConverterService.convertPkrToUsd(amount);
      
      // Store original PKR amount in metadata for reference
      final originalAmountPkr = amount;
      
      // Call Cloud Function to create payment intent with USD amount
      final callable = _functions.httpsCallable('stripeCreatePaymentIntent');
      final result = await callable.call({
        'amount': amountInUsd, // Send USD amount to Stripe
        'currency': StripeConfig.currency, // 'usd'
        'userId': user.uid,
        'transactionId': transactionId,
        'vehicleInvestmentId': additionalData?['vehicleInvestmentId'],
        'investmentId': additionalData?['investmentId'],
        'type': additionalData?['type'] ?? 'investment',
        'description': description,
        // Store original PKR amount in metadata
        'originalAmountPkr': originalAmountPkr,
      });

      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] != true || data['clientSecret'] == null) {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to create payment intent',
        };
      }

      final clientSecret = data['clientSecret'] as String;
      final paymentIntentId = _extractPaymentIntentId(clientSecret);

      // Web: Stripe payment sheet is not supported on web
      // We need to use Stripe Checkout or Stripe Elements
      if (kIsWeb) {
        // For web, we'll return a helpful error message
        // In production, you should implement one of:
        // 1. Stripe Checkout Session (redirect-based, easiest)
        // 2. Stripe Elements (embedded form, more complex)
        return {
          'success': false,
          'error': 'Stripe card payments are currently only available on mobile devices. '
              'Please use the mobile app, or choose another payment method (JazzCash, EasyPay, Bank Transfer).',
          'paymentIntentId': paymentIntentId, // Return for reference
        };
      }

      // Mobile: Use native payment sheet
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'CarHive',
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Confirm payment with backend
      final confirmCallable = _functions.httpsCallable('stripeConfirmPayment');
      final confirmResult = await confirmCallable.call({
        'paymentIntentId': paymentIntentId,
        'transactionId': transactionId,
        'userId': user.uid,
      });

      final confirmData = confirmResult.data as Map<String, dynamic>;

      if (confirmData['success'] == true) {
        return {
          'success': true,
          'reference': paymentIntentId,
          'message': 'Payment processed successfully',
        };
      } else {
        return {
          'success': false,
          'error': confirmData['error'] ?? 'Payment confirmation failed',
        };
      }
    } on StripeException catch (e) {
      return {
        'success': false,
        'error': _getStripeErrorMessage(e),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Payment processing error: $e',
      };
    }
  }


  /// Extract payment intent ID from client secret
  String _extractPaymentIntentId(String clientSecret) {
    // Client secret format: pi_xxx_secret_xxx
    final parts = clientSecret.split('_secret_');
    return parts.isNotEmpty ? parts[0] : clientSecret;
  }

  /// Get user-friendly error message from Stripe exception
  String _getStripeErrorMessage(StripeException e) {
    final codeString = e.error.code.toString();
    switch (codeString) {
      case 'FailureCode.card_declined':
        return 'Your card was declined. Please try a different card.';
      case 'FailureCode.expired_card':
        return 'Your card has expired. Please use a different card.';
      case 'FailureCode.incorrect_cvc':
        return 'The card security code is incorrect.';
      case 'FailureCode.insufficient_funds':
        return 'Insufficient funds. Please try a different card.';
      case 'FailureCode.invalid_cvc':
        return 'The card security code is invalid.';
      case 'FailureCode.invalid_expiry_month':
        return 'The card expiration month is invalid.';
      case 'FailureCode.invalid_expiry_year':
        return 'The card expiration year is invalid.';
      case 'FailureCode.invalid_number':
        return 'The card number is invalid.';
      case 'FailureCode.payment_intent_authentication_failure':
        return 'Payment authentication failed. Please try again.';
      case 'FailureCode.payment_intent_payment_attempt_failed':
        return 'Payment attempt failed. Please try again.';
      default:
        return e.error.message ?? 'Payment failed. Please try again.';
    }
  }

  /// Create Stripe payment intent (for direct use)
  Future<Map<String, dynamic>> createStripePaymentIntent({
    required double amount,
    required String userId,
    String? vehicleInvestmentId,
    String? investmentId,
    String? transactionId,
    String? type,
    String? description,
  }) async {
    try {
      final callable = _functions.httpsCallable('stripeCreatePaymentIntent');
      final result = await callable.call({
        'amount': amount,
        'currency': StripeConfig.currency,
        'userId': userId,
        'vehicleInvestmentId': vehicleInvestmentId,
        'investmentId': investmentId,
        'transactionId': transactionId,
        'type': type ?? 'investment',
        'description': description,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to create payment intent: $e',
      };
    }
  }

  /// Verify payment status
  /// 
  /// Check if a payment transaction was successful
  Future<Map<String, dynamic>> verifyPayment({
    required String transactionReference,
    required String paymentMethod,
  }) async {
    try {
      // TODO: Implement actual verification with payment gateway
      // This should query the payment gateway API to check transaction status

      // Simulate verification
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'verified': true,
        'status': 'completed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Verification failed: $e',
      };
    }
  }

  /// Refund a payment
  /// 
  /// Process a refund for a completed payment
  Future<Map<String, dynamic>> refundPayment({
    required String transactionReference,
    required String paymentMethod,
    required double amount,
    String? reason,
  }) async {
    try {
      // TODO: Implement actual refund with payment gateway
      // This should call the payment gateway's refund API

      // Simulate refund processing
      await Future.delayed(const Duration(seconds: 2));

      return {
        'success': true,
        'refundReference': 'REF${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Refund processed successfully (Simulated)',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Refund failed: $e',
      };
    }
  }

  /// Get payment methods available for the user
  List<String> getAvailablePaymentMethods() {
    return ['jazzcash', 'easypay', 'bank_transfer', 'stripe'];
  }

  /// Get payment method display name
  String getPaymentMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'jazzcash':
        return 'JazzCash';
      case 'easypay':
        return 'EasyPay';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'card':
      case 'stripe':
        return 'Debit/Credit Card (Stripe)';
      default:
        return method;
    }
  }

  /// Create Stripe payout for profit distribution
  Future<Map<String, dynamic>> createStripePayout({
    required double amount,
    required String userId,
    required String transactionId,
    required String vehicleInvestmentId,
    String? investmentId,
    String? description,
  }) async {
    try {
      final callable = _functions.httpsCallable('stripeCreatePayout');
      final result = await callable.call({
        'amount': amount,
        'currency': StripeConfig.currency,
        'userId': userId,
        'transactionId': transactionId,
        'vehicleInvestmentId': vehicleInvestmentId,
        'investmentId': investmentId,
        'description': description ?? 'Profit distribution payout',
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to create payout: $e',
      };
    }
  }
}

