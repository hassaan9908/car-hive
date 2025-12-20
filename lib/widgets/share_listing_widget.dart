import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/investment_model.dart';
import '../models/investment_vehicle_model.dart';
import '../services/investment_service.dart';
import '../services/share_marketplace_service.dart';

class ShareListingWidget extends StatefulWidget {
  final InvestmentModel investment;
  final InvestmentVehicleModel vehicle;
  final VoidCallback onListingComplete;
  final VoidCallback onCancel;

  const ShareListingWidget({
    super.key,
    required this.investment,
    required this.vehicle,
    required this.onListingComplete,
    required this.onCancel,
  });

  @override
  State<ShareListingWidget> createState() => _ShareListingWidgetState();
}

class _ShareListingWidgetState extends State<ShareListingWidget> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final InvestmentService _investmentService = InvestmentService();
  final ShareMarketplaceService _marketplaceService = ShareMarketplaceService();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with original investment amount as default
    _priceController.text = widget.investment.amount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double? _getAskingPrice() {
    try {
      return double.parse(_priceController.text.trim());
    } catch (e) {
      return null;
    }
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter asking price';
    }

    final price = _getAskingPrice();
    if (price == null) {
      return 'Please enter a valid number';
    }

    if (price <= 0) {
      return 'Price must be greater than 0';
    }

    // Warn if price is significantly lower than original investment
    if (price < widget.investment.amount * 0.5) {
      return 'Price is less than 50% of original investment. Are you sure?';
    }

    return null;
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final askingPrice = _getAskingPrice();
    if (askingPrice == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // List shares for sale in investment
      await _investmentService.listSharesForSale(
        investmentId: widget.investment.id,
        askingPrice: askingPrice,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      // Create marketplace listing
      await _marketplaceService.createShareListing(
        investmentId: widget.investment.id,
        vehicleInvestmentId: widget.investment.vehicleInvestmentId,
        sellerUserId: widget.investment.userId,
        sharePercentage: widget.investment.investmentRatio,
        askingPrice: askingPrice,
        originalInvestment: widget.investment.amount,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shares listed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onListingComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error listing shares: $e'),
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
    final shareValue = widget.vehicle.salePrice > 0
        ? widget.vehicle.salePrice * widget.investment.investmentRatio
        : widget.investment.amount;

    return Card(
      elevation: 4,
      color: Colors.orange[50],
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
                    'List Shares for Sale',
                    style: TextStyle(
                      fontSize: 18,
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

              // Share Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Your Share', '${(widget.investment.investmentRatio * 100).toStringAsFixed(2)}%'),
                    const SizedBox(height: 4),
                    _buildInfoRow('Original Investment', '${widget.investment.amount.toStringAsFixed(0)} PKR'),
                    const SizedBox(height: 4),
                    _buildInfoRow('Estimated Current Value', '${shareValue.toStringAsFixed(0)} PKR'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Asking Price
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Asking Price (PKR)',
                  hintText: 'Enter price you want to sell for',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: _validatePrice,
              ),
              const SizedBox(height: 8),

              // Price Comparison
              if (_getAskingPrice() != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getAskingPrice()! >= widget.investment.amount
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getAskingPrice()! >= widget.investment.amount
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 16,
                        color: _getAskingPrice()! >= widget.investment.amount
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getAskingPrice()! >= widget.investment.amount
                              ? 'Premium: ${((_getAskingPrice()! - widget.investment.amount) / widget.investment.amount * 100).toStringAsFixed(2)}%'
                              : 'Discount: ${((widget.investment.amount - _getAskingPrice()!) / widget.investment.amount * 100).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getAskingPrice()! >= widget.investment.amount
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Why are you selling?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitListing,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
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
                          'List Shares',
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
}

