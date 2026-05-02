import 'package:carhive/ads/visit_booking_confirmation.dart';
import 'package:carhive/services/payment_service.dart';
import 'package:carhive/services/visit_service.dart';
import 'package:carhive/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:intl/intl.dart';

class CheckoutScreen extends StatefulWidget {
  final String carModel;
  final String carYear;
  final String engine;
  final String registeredCity;
  final String assembly;
  final String selectedCity;
  final String selectedArea;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String? carAdId;
  final String? carImageUrl;

  const CheckoutScreen({
    super.key,
    required this.carModel,
    required this.carYear,
    required this.engine,
    required this.registeredCity,
    required this.assembly,
    required this.selectedCity,
    required this.selectedArea,
    required this.selectedDate,
    required this.selectedTimeSlot,
    this.carAdId,
    this.carImageUrl,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedMethod = 'Debit/Credit Card';
  final TextEditingController _voucherController = TextEditingController();
  bool voucherApplied = false;
  bool _isProcessing = false;

  final PaymentService _paymentService = PaymentService();
  final VisitService _visitService = VisitService();

  final List<String> paymentMethods = const [
    'Debit/Credit Card',
    'JazzCash Mobile Account',
    'EasyPay Mobile Account',
    'Stripe',
    'JazzCash Shop',
  ];

  final Map<String, IconData> methodIcons = const {
    'Debit/Credit Card': Icons.credit_card,
    'JazzCash Mobile Account': Icons.mobile_friendly,
    'EasyPay Mobile Account': Icons.payment,
    'Stripe': Icons.payment_rounded,
    'JazzCash Shop': Icons.storefront,
  };

  static const double _totalAmount = 5000;
  static const double _discountAmount = 500;

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  String get _carTitle {
    final title = '${widget.carModel} ${widget.carYear}'.trim();
    return title.isEmpty ? 'CarHive Assisted Visit' : title;
  }

  double get _finalAmount {
    return voucherApplied ? _totalAmount - _discountAmount : _totalAmount;
  }

  Future<void> _handlePayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final transactionId = 'visit_${DateTime.now().millisecondsSinceEpoch}';
      var paymentMethodKey = selectedMethod.toLowerCase();

      if (paymentMethodKey.contains('jazzcash')) {
        paymentMethodKey = 'jazzcash';
      } else if (paymentMethodKey.contains('easypay')) {
        paymentMethodKey = 'easypay';
      } else if (paymentMethodKey == 'debit/credit card') {
        paymentMethodKey = 'stripe';
      } else if (paymentMethodKey == 'stripe') {
        paymentMethodKey = 'stripe';
      }

      Map<String, dynamic> paymentResult;

      if (paymentMethodKey == 'stripe') {
        paymentResult = await _paymentService.createStripePaymentIntent(
          amount: _finalAmount,
          userId: user.uid,
          type: 'visit_booking',
          description: 'Car Visit Booking - $_carTitle',
        );

        if (paymentResult['success'] == true &&
            paymentResult['clientSecret'] != null) {
          try {
            await Stripe.instance.initPaymentSheet(
              paymentSheetParameters: SetupPaymentSheetParameters(
                paymentIntentClientSecret: paymentResult['clientSecret'],
                merchantDisplayName: 'CarHive',
              ),
            );

            await Stripe.instance.presentPaymentSheet();
            paymentResult = <String, dynamic>{
              'success': true,
              'reference': transactionId,
            };
          } catch (error) {
            paymentResult = <String, dynamic>{
              'success': false,
              'error': 'Payment cancelled or failed: $error',
            };
          }
        }
      } else {
        paymentResult = <String, dynamic>{
          'success': true,
          'message': 'Payment method selected. Processing...',
        };
      }

      if (paymentResult['success'] != true) {
        throw Exception(paymentResult['error'] ?? 'Payment failed.');
      }

      await _visitService.createVisitBooking(
        city: widget.selectedCity,
        area: widget.selectedArea,
        date: widget.selectedDate,
        timeSlot: widget.selectedTimeSlot,
        paymentMethod: selectedMethod,
        amount: _finalAmount,
        carAdId: widget.carAdId,
        carTitle: _carTitle,
        carYear: widget.carYear,
        engine: widget.engine,
        registeredCity: widget.registeredCity,
        assembly: widget.assembly,
        carImageUrl: widget.carImageUrl,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VisitBookingConfirmationPage(
            carTitle: _carTitle,
            city: widget.selectedCity,
            area: widget.selectedArea,
            visitDate: widget.selectedDate,
            timeSlot: widget.selectedTimeSlot,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.dividerColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _step(context, '1', completed: true, label: 'Info'),
                _stepLine(context),
                _step(context, '2', completed: true, label: 'Visit'),
                _stepLine(context),
                _step(context, '3',
                    completed: true, label: 'Checkout', active: true),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              color: theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DetailRow(label: 'Car', value: _carTitle),
                    _DetailRow(label: 'Engine', value: widget.engine),
                    _DetailRow(
                        label: 'Registered City', value: widget.registeredCity),
                    _DetailRow(label: 'Assembly', value: widget.assembly),
                    _DetailRow(
                      label: 'Visit Date',
                      value:
                          DateFormat('dd MMM yyyy').format(widget.selectedDate),
                    ),
                    _DetailRow(
                        label: 'Time Slot', value: widget.selectedTimeSlot),
                    _DetailRow(
                      label: 'Location',
                      value: '${widget.selectedArea}, ${widget.selectedCity}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discount Voucher',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _voucherController,
                            enabled: !voucherApplied,
                            decoration: InputDecoration(
                              labelText: 'Enter code',
                              prefixIcon:
                                  const Icon(Icons.local_offer_outlined),
                              suffixIcon: voucherApplied
                                  ? Icon(
                                      Icons.check_circle,
                                      color: colorScheme.primary,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (!voucherApplied)
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.greenAction,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              disabledForegroundColor: theme
                                  .textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                            onPressed: () {
                              if (_voucherController.text.trim().isEmpty) {
                                return;
                              }
                              setState(() {
                                voucherApplied = true;
                              });
                            },
                            child: const Text('Apply'),
                          )
                        else
                          TextButton(
                            onPressed: () {
                              setState(() {
                                voucherApplied = false;
                                _voucherController.clear();
                              });
                            },
                            child: const Text('Remove'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Payment Method',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...paymentMethods.map(
              (method) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RadioListTile<String>(
                  value: method,
                  groupValue: selectedMethod,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      selectedMethod = value;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: theme.cardColor,
                  secondary:
                      Icon(methodIcons[method], color: colorScheme.primary),
                  title: Text(method),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _PriceRow(
                      label: 'Subtotal',
                      value: 'PKR ${_totalAmount.toStringAsFixed(0)}',
                    ),
                    if (voucherApplied) ...[
                      const SizedBox(height: 8),
                      _PriceRow(
                        label: 'Discount',
                        value: '- PKR ${_discountAmount.toStringAsFixed(0)}',
                      ),
                    ],
                    const Divider(height: 24),
                    _PriceRow(
                      label: 'Total',
                      value: 'PKR ${_finalAmount.toStringAsFixed(0)}',
                      emphasize: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isProcessing ? null : _handlePayment,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(
    BuildContext context,
    String number, {
    required bool completed,
    required String label,
    bool active = false,
  }) {
    final theme = Theme.of(context);
    final color =
        completed || active ? theme.colorScheme.primary : theme.dividerColor;

    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color,
          child: completed
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(BuildContext context) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Theme.of(context).dividerColor,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
