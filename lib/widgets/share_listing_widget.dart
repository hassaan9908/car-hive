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
    final theme = Theme.of(context);
    final shareValue = widget.vehicle.salePrice > 0
        ? widget.vehicle.salePrice * widget.investment.investmentRatio
        : widget.investment.amount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 6),
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
                  'List Shares for Sale',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: theme.colorScheme.onSurfaceVariant),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Share Information
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
                  _buildInfoRow('Your Share',
                      '${(widget.investment.investmentRatio * 100).toStringAsFixed(2)}%'),
                  Divider(color: theme.colorScheme.surfaceVariant, height: 16),
                  _buildInfoRow('Original Investment',
                      '${widget.investment.amount.toStringAsFixed(0)} PKR'),
                  Divider(color: theme.colorScheme.surfaceVariant, height: 16),
                  _buildInfoRow('Estimated Current Value',
                      '${shareValue.toStringAsFixed(0)} PKR'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Asking Price
            TextFormField(
              controller: _priceController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Asking Price (PKR)',
                hintText: 'Enter price you want to sell for',
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
                      BorderSide(color: const Color(0xFFFF6B35), width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: _validatePrice,
            ),
            const SizedBox(height: 12),

            // Price Comparison
            if (_getAskingPrice() != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_getAskingPrice()! >= widget.investment.amount
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF44336))
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_getAskingPrice()! >= widget.investment.amount
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFF44336))
                        .withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getAskingPrice()! >= widget.investment.amount
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 20,
                      color: _getAskingPrice()! >= widget.investment.amount
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF44336),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getAskingPrice()! >= widget.investment.amount
                            ? 'Premium: ${((_getAskingPrice()! - widget.investment.amount) / widget.investment.amount * 100).toStringAsFixed(2)}%'
                            : 'Discount: ${((widget.investment.amount - _getAskingPrice()!) / widget.investment.amount * 100).toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _getAskingPrice()! >= widget.investment.amount
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFF44336),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Description
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Why are you selling?',
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: const Color(0xFFFF6B35), width: 2),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitListing,
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
                          'List Shares',
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
}
