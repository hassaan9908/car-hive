import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/investment_vehicle_model.dart';
import '../services/investment_service.dart';
import '../services/investment_vehicle_service.dart';
import '../services/investment_transaction_service.dart';
import '../services/payment_service.dart';

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
  final List<String> _paymentMethods = [
    'jazzcash',
    'easypay',
    'bank_transfer',
    'stripe',
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

    if (amount < widget.vehicle.minimumContribution) {
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
              content: Text('Payment failed: ${paymentResult['error'] ?? 'Unknown error'}'),
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
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Make Investment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Investment Amount Input
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Investment Amount (PKR)',
                  hintText: 'Enter amount',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: _validateAmount,
              ),
              const SizedBox(height: 8),

              // Investment Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'Minimum',
                      '${widget.vehicle.minimumContribution.toStringAsFixed(0)} PKR',
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      'Remaining',
                      '${widget.vehicle.remainingAmount.toStringAsFixed(0)} PKR',
                    ),
                    const SizedBox(height: 4),
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
              const SizedBox(height: 16),

              // Payment Method Selection
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._paymentMethods.map((method) {
                return RadioListTile<String>(
                  title: Text(_getPaymentMethodName(method)),
                  value: method,
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                );
              }),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitInvestment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
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
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
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

