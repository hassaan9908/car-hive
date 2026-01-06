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

  String _sortBy = 'default'; // default, price_asc, price_desc, name, fuel

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Marketplace'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          if (user != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Sort & Filter',
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort,
                        color: _sortBy == 'default'
                            ? const Color(0xFFFF6B35)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Default',
                        style: TextStyle(
                          fontWeight: _sortBy == 'default'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _sortBy == 'default'
                              ? const Color(0xFFFF6B35)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'price_asc',
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        color: _sortBy == 'price_asc'
                            ? const Color(0xFFFF6B35)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Price: Low to High',
                        style: TextStyle(
                          fontWeight: _sortBy == 'price_asc'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _sortBy == 'price_asc'
                              ? const Color(0xFFFF6B35)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'price_desc',
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        color: _sortBy == 'price_desc'
                            ? const Color(0xFFFF6B35)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Price: High to Low',
                        style: TextStyle(
                          fontWeight: _sortBy == 'price_desc'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _sortBy == 'price_desc'
                              ? const Color(0xFFFF6B35)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'share_percentage',
                  child: Row(
                    children: [
                      Icon(
                        Icons.percent,
                        color: _sortBy == 'share_percentage'
                            ? const Color(0xFFFF6B35)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Share Percentage',
                        style: TextStyle(
                          fontWeight: _sortBy == 'share_percentage'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _sortBy == 'share_percentage'
                              ? const Color(0xFFFF6B35)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: StreamBuilder<List<ShareMarketplaceModel>>(
        stream: widget.vehicleInvestmentId != null
            ? _marketplaceService
                .getShareListingsForVehicle(widget.vehicleInvestmentId!)
            : _marketplaceService.getActiveShareListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var listings = snapshot.data ?? [];

          // Apply sorting
          if (_sortBy != 'default' && listings.isNotEmpty) {
            listings = List.from(listings);
            switch (_sortBy) {
              case 'price_asc':
                listings.sort((a, b) => a.askingPrice.compareTo(b.askingPrice));
                break;
              case 'price_desc':
                listings.sort((a, b) => b.askingPrice.compareTo(a.askingPrice));
                break;
              case 'share_percentage':
                listings.sort(
                    (a, b) => b.sharePercentage.compareTo(a.sharePercentage));
                break;
            }
          }

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
      future:
          _vehicleService.getInvestmentVehicleById(listing.vehicleInvestmentId),
      builder: (context, snapshot) {
        final vehicle = snapshot.data;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
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
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                vehicle.imageUrls!.first,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.directions_car,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${vehicle.year} • ${vehicle.fuel}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
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
                        color: isDark
                            ? theme.colorScheme.surfaceVariant
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Share Percentage:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '${listing.sharePercentage.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Original Investment:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '${listing.originalInvestment.toStringAsFixed(0)} PKR',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Asking Price:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '${listing.askingPrice.toStringAsFixed(0)} PKR',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: listing.priceChangePercentage >= 0
                                  ? const Color(0xFF4CAF50).withOpacity(0.15)
                                  : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  listing.priceChangePercentage >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  size: 18,
                                  color: listing.priceChangePercentage >= 0
                                      ? const Color(0xFF4CAF50)
                                      : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  listing.priceChangePercentage >= 0
                                      ? 'Premium: ${listing.priceChangePercentage.toStringAsFixed(2)}%'
                                      : 'Discount: ${listing.priceChangePercentage.abs().toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: listing.priceChangePercentage >= 0
                                        ? const Color(0xFF4CAF50)
                                        : Colors.red,
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
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Purchase Button
                    if (_auth.currentUser != null &&
                        _auth.currentUser!.uid != listing.sellerUserId)
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _purchaseShares(listing),
                          icon: const Icon(Icons.shopping_cart,
                              color: Colors.white),
                          label: const Text(
                            'Purchase Shares',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    else if (_auth.currentUser != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Your listing',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
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
            Text(
                'Share Percentage: ${listing.sharePercentage.toStringAsFixed(2)}%'),
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
        description:
            'Purchase of ${listing.sharePercentage.toStringAsFixed(2)}% shares',
        additionalData: {
          'vehicleInvestmentId': listing.vehicleInvestmentId,
          'investmentId': listing.investmentId,
          'type': 'share_purchase',
        },
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
              title: const Text('Debit/Credit Card (Stripe)'),
              onTap: () => Navigator.pop(context, 'stripe'),
            ),
          ],
        ),
      ),
    );
  }
}
