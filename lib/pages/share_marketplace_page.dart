import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/share_marketplace_model.dart';
import '../models/investment_vehicle_model.dart';
import '../services/share_marketplace_service.dart';
import '../services/investment_vehicle_service.dart';
import '../services/investment_service.dart';
import '../services/investment_transaction_service.dart';
import '../services/payment_service.dart';
import 'investment_detail_page.dart';

class ShareMarketplacePage extends StatefulWidget {
  final String? vehicleInvestmentId;

  const ShareMarketplacePage({
    super.key,
    this.vehicleInvestmentId,
  });

  @override
  State<ShareMarketplacePage> createState() => _ShareMarketplacePageState();
}

class _ShareMarketplacePageState extends State<ShareMarketplacePage> {
  final ShareMarketplaceService _marketplaceService = ShareMarketplaceService();
  final InvestmentVehicleService _vehicleService = InvestmentVehicleService();
  final InvestmentService _investmentService = InvestmentService();
  final InvestmentTransactionService _transactionService =
      InvestmentTransactionService();
  final PaymentService _paymentService = PaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedVehicleFilter;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Marketplace'),
        backgroundColor: Colors.transparent,
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
        ],
      ),
      body: StreamBuilder<List<ShareMarketplaceModel>>(
        stream: widget.vehicleInvestmentId != null
            ? _marketplaceService.getShareListingsForVehicle(
                widget.vehicleInvestmentId!)
            : _marketplaceService.getActiveShareListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final listings = snapshot.data ?? [];

          if (listings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No shares available for purchase',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return _buildShareListingCard(listing);
            },
          );
        },
      ),
    );
  }

  Widget _buildShareListingCard(ShareMarketplaceModel listing) {
    return FutureBuilder<InvestmentVehicleModel?>(
      future: _vehicleService.getInvestmentVehicleById(listing.vehicleInvestmentId),
      builder: (context, snapshot) {
        final vehicle = snapshot.data;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvestmentDetailPage(
                    vehicleInvestmentId: listing.vehicleInvestmentId,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Info
                  if (vehicle != null) ...[
                    Row(
                      children: [
                        if (vehicle.imageUrls != null &&
                            vehicle.imageUrls!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              vehicle.imageUrls!.first,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                );
                              },
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${vehicle.year} • ${vehicle.fuel}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Share Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Share Percentage:'),
                            Text(
                              '${listing.sharePercentage.toStringAsFixed(2)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Original Investment:'),
                            Text(
                              '${listing.originalInvestment.toStringAsFixed(0)} PKR',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Asking Price:'),
                            Text(
                              '${listing.askingPrice.toStringAsFixed(0)} PKR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: listing.priceChangePercentage >= 0
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                listing.priceChangePercentage >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 16,
                                color: listing.priceChangePercentage >= 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                listing.priceChangePercentage >= 0
                                    ? 'Premium: ${listing.priceChangePercentage.toStringAsFixed(2)}%'
                                    : 'Discount: ${listing.priceChangePercentage.abs().toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: listing.priceChangePercentage >= 0
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (listing.description != null &&
                      listing.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      listing.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Purchase Button
                  if (_auth.currentUser != null &&
                      _auth.currentUser!.uid != listing.sellerUserId)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _purchaseShares(listing),
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Purchase Shares'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  else if (_auth.currentUser != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 16),
                          SizedBox(width: 8),
                          Text('Your listing'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _purchaseShares(ShareMarketplaceModel listing) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to purchase shares')),
      );
      return;
    }

    if (user.uid == listing.sellerUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot purchase your own shares')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Shares'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share Percentage: ${listing.sharePercentage.toStringAsFixed(2)}%'),
            Text('Price: ${listing.askingPrice.toStringAsFixed(0)} PKR'),
            const SizedBox(height: 16),
            const Text('Are you sure you want to purchase these shares?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show payment method selection
    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return;

    // Process purchase
    try {
      // Get the investment being sold
      final investments = await _investmentService
          .getInvestmentsForVehicle(listing.vehicleInvestmentId)
          .first;
      final sellerInvestment = investments.firstWhere(
        (inv) => inv.id == listing.investmentId,
      );

      // Create transaction
      final transactionId = await _transactionService.createTransaction(
        vehicleInvestmentId: listing.vehicleInvestmentId,
        investmentId: listing.investmentId,
        userId: user.uid,
        type: 'share_purchase',
        amount: listing.askingPrice,
        status: 'pending',
        paymentMethod: paymentMethod,
        sharePrice: listing.askingPrice,
        sharePercentage: listing.sharePercentage,
      );

      // Process payment
      final paymentResult = await _paymentService.processPayment(
        amount: listing.askingPrice,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        description: 'Purchase of ${listing.sharePercentage.toStringAsFixed(2)}% shares',
      );

      if (paymentResult['success'] == true) {
        // Update transaction
        await _transactionService.updateTransactionPayment(
          transactionId,
          paymentMethod,
          paymentResult['reference'] ?? '',
        );

        // Transfer investment ownership
        await _investmentService.transferInvestmentOwnership(
          listing.investmentId,
          user.uid,
        );

        // Mark marketplace listing as sold
        await _marketplaceService.markShareListingSold(
          listing.id,
          user.uid,
          listing.askingPrice,
        );

        // Mark transaction as completed
        await _transactionService.markTransactionCompleted(transactionId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shares purchased successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
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
            content: Text('Error purchasing shares: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showPaymentMethodDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mobile_friendly),
              title: const Text('JazzCash'),
              onTap: () => Navigator.pop(context, 'jazzcash'),
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('EasyPay'),
              onTap: () => Navigator.pop(context, 'easypay'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Bank Transfer'),
              onTap: () => Navigator.pop(context, 'bank_transfer'),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Debit/Credit Card'),
              onTap: () => Navigator.pop(context, 'card'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    // TODO: Implement filter dialog for filtering by vehicle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter functionality coming soon')),
    );
  }
}

