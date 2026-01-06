import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/investment_vehicle_model.dart';
import '../services/investment_service.dart';
import '../services/investment_vehicle_service.dart';
import '../services/investment_transaction_service.dart';
import '../services/payment_service.dart';
import '../services/currency_converter_service.dart';

class InvestmentFormWidget extends StatefulWidget {
  final InvestmentVehicleModel vehicle;
  final VoidCallback onInvestmentComplete;
  final VoidCallback onCancel;

  const InvestmentFormWidget({
    super.key,
    required this.vehicle,
    required this.onInvestmentComplete,
    required this.onCancel,
  });

  @override
  State<InvestmentFormWidget> createState() => _InvestmentFormWidgetState();
}

class _InvestmentFormWidgetState extends State<InvestmentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final InvestmentService _investmentService = InvestmentService();
  final InvestmentVehicleService _vehicleService = InvestmentVehicleService();
  final InvestmentTransactionService _transactionService =
      InvestmentTransactionService();
  final PaymentService _paymentService = PaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSubmitting = false;
  String? _selectedPaymentMethod;
  
  // Payment methods - exclude Stripe on web since payment sheet doesn't work on web
  List<String> get _paymentMethods => [
    'jazzcash',
    'easypay',
    'bank_transfer',
    if (!kIsWeb) 'stripe', // Stripe only on mobile (payment sheet not supported on web)
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? _getInvestmentAmount() {
    try {
      final amount = double.parse(_amountController.text.trim());
      return amount;
    } catch (e) {
      return null;
    }
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter investment amount';
    }

    final amount = _getInvestmentAmount();
    if (amount == null) {
      return 'Please enter a valid number';
    }

    // Get the effective minimum: if remaining amount is less than minimum,
    // allow investing the exact remaining amount
    final effectiveMinimum = widget.vehicle.remainingAmount < widget.vehicle.minimumContribution
        ? widget.vehicle.remainingAmount
        : widget.vehicle.minimumContribution;

    if (amount < effectiveMinimum) {
      if (widget.vehicle.remainingAmount < widget.vehicle.minimumContribution) {
        return 'You can invest the remaining amount: ${widget.vehicle.remainingAmount.toStringAsFixed(0)} PKR';
      }
      return 'Minimum investment is ${widget.vehicle.minimumContribution.toStringAsFixed(0)} PKR';
    }

    if (amount > widget.vehicle.remainingAmount) {
      return 'Maximum investment is ${widget.vehicle.remainingAmount.toStringAsFixed(0)} PKR';
    }

    return null;
  }

  Future<void> _submitInvestment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to invest')),
      );
      return;
    }

    final amount = _getInvestmentAmount();
    if (amount == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create investment record
      final investmentId = await _investmentService.createInvestment(
        vehicleInvestmentId: widget.vehicle.id,
        amount: amount,
        totalInvestmentGoal: widget.vehicle.totalInvestmentGoal,
      );

      // Create transaction record
      final transactionId = await _transactionService.createTransaction(
        vehicleInvestmentId: widget.vehicle.id,
        investmentId: investmentId,
        userId: user.uid,
        type: 'investment',
        amount: amount,
        status: 'pending',
        paymentMethod: _selectedPaymentMethod,
      );

      // Process payment
      final paymentResult = await _paymentService.processPayment(
        amount: amount,
        paymentMethod: _selectedPaymentMethod!,
        transactionId: transactionId,
        description: 'Investment in ${widget.vehicle.title}',
        additionalData: {
          'vehicleInvestmentId': widget.vehicle.id,
          'investmentId': investmentId,
          'type': 'investment',
        },
      );

      if (paymentResult['success'] == true) {
        // Update transaction with payment reference
        await _transactionService.updateTransactionPayment(
          transactionId,
          _selectedPaymentMethod!,
          paymentResult['reference'] ?? '',
        );

        // Activate investment
        await _investmentService.activateInvestment(investmentId);

        // Update vehicle current investment
        await _vehicleService.updateCurrentInvestment(
          widget.vehicle.id,
          amount,
        );

        // Check if funding is complete
        await _vehicleService.checkFundingComplete(widget.vehicle.id);

        // Mark transaction as completed
        await _transactionService.markTransactionCompleted(transactionId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Investment successful!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onInvestmentComplete();
        }
      } else {
        // Payment failed
        await _transactionService.markTransactionFailed(
          transactionId,
          notes: paymentResult['error'] ?? 'Payment failed',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Payment failed: ${paymentResult['error'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Make Investment',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: theme.colorScheme.onSurfaceVariant),
                  onPressed: widget.onCancel,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Investment Amount Input
            TextFormField(
              controller: _amountController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Investment Amount (PKR)',
                hintText: 'Enter amount',
                prefixIcon: Icon(Icons.attach_money,
                    color: theme.colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: const Color(0xFF4CAF50), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.error, width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: _validateAmount,
            ),
            const SizedBox(height: 16),

            // Investment Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Minimum',
                    '${widget.vehicle.minimumContribution.toStringAsFixed(0)} PKR',
                  ),
                  Divider(color: theme.colorScheme.surfaceVariant, height: 16),
                  _buildInfoRow(
                    'Remaining',
                    '${widget.vehicle.remainingAmount.toStringAsFixed(0)} PKR',
                  ),
                  Divider(color: theme.colorScheme.surfaceVariant, height: 16),
                  _buildInfoRow(
                    'Your Share',
                    _amountController.text.isNotEmpty &&
                            _getInvestmentAmount() != null
                        ? '${((_getInvestmentAmount()! / widget.vehicle.totalInvestmentGoal) * 100).toStringAsFixed(2)}%'
                        : '0%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Method Selection
            Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ..._paymentMethods.map((method) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _selectedPaymentMethod == method
                      ? const Color(0xFF4CAF50).withOpacity(0.12)
                      : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedPaymentMethod == method
                        ? const Color(0xFF4CAF50)
                        : theme.colorScheme.surfaceVariant,
                    width: _selectedPaymentMethod == method ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Show effective minimum (remaining if less than minimum)
                    _buildInfoRow(
                      'Minimum',
                      widget.vehicle.remainingAmount < widget.vehicle.minimumContribution
                          ? '${widget.vehicle.remainingAmount.toStringAsFixed(0)} PKR (remaining)'
                          : '${widget.vehicle.minimumContribution.toStringAsFixed(0)} PKR',
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      'Remaining',
                      '${widget.vehicle.remainingAmount.toStringAsFixed(0)} PKR',
                    ),
                    const SizedBox(height: 4),
                    // Show USD equivalent if Stripe is selected
                    if (_selectedPaymentMethod == 'stripe' && 
                        _amountController.text.isNotEmpty &&
                        _getInvestmentAmount() != null) ...[
                      _buildInfoRow(
                        'Amount (USD)',
                        CurrencyConverterService.formatCurrency(
                          CurrencyConverterService.convertPkrToUsd(_getInvestmentAmount()!),
                          currency: 'USD',
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    _buildInfoRow(
                      'Your Share',
                      _amountController.text.isNotEmpty &&
                              _getInvestmentAmount() != null
                          ? '${((_getInvestmentAmount()! / widget.vehicle.totalInvestmentGoal) * 100).toStringAsFixed(2)}%'
                          : '0%',
                child: RadioListTile<String>(
                  title: Text(
                    _getPaymentMethodName(method),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: _selectedPaymentMethod == method
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  value: method,
                  groupValue: _selectedPaymentMethod,
                  activeColor: const Color(0xFF4CAF50),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitInvestment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Invest Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'jazzcash':
        return 'JazzCash';
      case 'easypay':
        return 'EasyPay';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'stripe':
        return 'Debit/Credit Card (Stripe)';
      default:
        return method;
    }
  }
}
