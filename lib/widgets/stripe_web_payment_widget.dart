import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:js' as js;

/// Web-specific Stripe payment widget
/// Uses Stripe.js to handle payments on web
class StripeWebPaymentWidget extends StatefulWidget {
  final String clientSecret;
  final String paymentIntentId;
  final Function(String paymentIntentId) onSuccess;
  final Function(String error) onError;

  const StripeWebPaymentWidget({
    super.key,
    required this.clientSecret,
    required this.paymentIntentId,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<StripeWebPaymentWidget> createState() => _StripeWebPaymentWidgetState();
}

class _StripeWebPaymentWidgetState extends State<StripeWebPaymentWidget> {
  bool _isProcessing = false;
  bool _isStripeLoaded = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadStripe();
    }
  }

  /// Load Stripe.js library
  void _loadStripe() {
    if (html.document.getElementById('stripe-js') != null) {
      setState(() => _isStripeLoaded = true);
      return;
    }

    final script = html.ScriptElement()
      ..id = 'stripe-js'
      ..src = 'https://js.stripe.com/v3/'
      ..type = 'text/javascript';
    
    html.document.head!.append(script);
    
    script.onLoad.listen((_) {
      setState(() => _isStripeLoaded = true);
    });
  }

  /// Process payment using Stripe.js
  Future<void> _processPayment() async {
    if (!_isStripeLoaded) {
      widget.onError('Stripe.js is not loaded yet. Please wait...');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Get Stripe instance
      final stripe = js.context.callMethod('eval', [
        'Stripe("pk_test_51SgTrF06P57eoMHk2npQbiU3HeWYo9ruCZPzTx9jg0vLCgGy6q0asl5F3NsBKJB2XCOMx3cNvhnFEIiLLMLuyB2Z00EPYdmX9B")'
      ]);

      // Confirm payment
      final result = js.context.callMethod('eval', [
        '''
        (async function() {
          const stripe = Stripe("pk_test_51SgTrF06P57eoMHk2npQbiU3HeWYo9ruCZPzTx9jg0vLCgGy6q0asl5F3NsBKJB2XCOMx3cNvhnFEIiLLMLuyB2Z00EPYdmX9B");
          const {error} = await stripe.confirmCardPayment("${widget.clientSecret}");
          return error ? {error: error.message} : {success: true};
        })()
        '''
      ]);

      // Wait for promise to resolve
      await Future.delayed(const Duration(milliseconds: 100));

      // Note: This is a simplified approach. In production, you should use
      // Stripe Elements to collect card details and then confirm the payment.
      // For now, we'll show an error message directing users to use mobile app
      // or implement a proper Stripe Elements form.
      
      widget.onError(
        'Web payment requires Stripe Elements integration. '
        'Please use the mobile app for card payments, or contact support.'
      );
    } catch (e) {
      widget.onError('Payment processing error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Card Payment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Stripe payment on web requires additional setup.\n'
            'Please use the mobile app for card payments.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isProcessing ? null : () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

