import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/investment_model.dart';
import '../models/investment_vehicle_model.dart';
import '../services/investment_service.dart';
import '../services/investment_vehicle_service.dart';
import '../services/investment_transaction_service.dart';
import '../services/profit_distribution_service.dart';
import '../models/investment_transaction_model.dart';
import '../widgets/share_listing_widget.dart';

class MyInvestmentDetailPage extends StatefulWidget {
  final String investmentId;

  const MyInvestmentDetailPage({
    super.key,
    required this.investmentId,
  });

  @override
  State<MyInvestmentDetailPage> createState() => _MyInvestmentDetailPageState();
}

class _MyInvestmentDetailPageState extends State<MyInvestmentDetailPage> {
  final InvestmentService _investmentService = InvestmentService();
  final InvestmentVehicleService _vehicleService = InvestmentVehicleService();
  final InvestmentTransactionService _transactionService =
      InvestmentTransactionService();
  final ProfitDistributionService _profitService = ProfitDistributionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  InvestmentModel? _investment;
  InvestmentVehicleModel? _vehicle;
  bool _isLoading = true;
  bool _showShareListingForm = false;

  @override
  void initState() {
    super.initState();
    _loadInvestment();
  }

  Future<void> _loadInvestment() async {
    try {
      final investment =
          await _investmentService.getInvestmentById(widget.investmentId);
      if (investment == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Investment not found')),
          );
        }
        return;
      }

      final vehicle = await _vehicleService
          .getInvestmentVehicleById(investment.vehicleInvestmentId);

      if (mounted) {
        setState(() {
          _investment = investment;
          _vehicle = vehicle;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading investment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Investment'),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_investment == null || _vehicle == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Investment'),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: Text('Investment not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Investment'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Investment Summary Card
            _buildInvestmentSummaryCard(),
            const SizedBox(height: 16),

            // Vehicle Information
            _buildVehicleInfoCard(),
            const SizedBox(height: 16),

            // Profit Information
            _buildProfitCard(),
            const SizedBox(height: 16),

            // Share Management
            if (_investment!.status == 'active') _buildShareManagementSection(),
            const SizedBox(height: 16),

            // Transaction History
            _buildTransactionHistorySection(),
            const SizedBox(height: 16),

            // Profit History
            _buildProfitHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentSummaryCard() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Investment Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Investment Amount',
              '${_investment!.amount.toStringAsFixed(0)} PKR'),
          Divider(color: theme.colorScheme.surfaceVariant),
          _buildSummaryRow('Ownership Share',
              '${(_investment!.investmentRatio * 100).toStringAsFixed(2)}%'),
          Divider(color: theme.colorScheme.surfaceVariant),
          _buildSummaryRow(
              'Investment Date', _formatDate(_investment!.investmentDate)),
          Divider(color: theme.colorScheme.surfaceVariant),
          _buildSummaryRow('Status', _investment!.status.toUpperCase(),
              valueColor: _getStatusColor(_investment!.status)),
          if (_vehicle!.salePrice > 0) ...[
            Divider(color: theme.colorScheme.surfaceVariant),
            _buildSummaryRow('Current Vehicle Value',
                '${_vehicle!.salePrice.toStringAsFixed(0)} PKR',
                valueColor: const Color(0xFF4CAF50)),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (_vehicle!.imageUrls != null && _vehicle!.imageUrls!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _vehicle!.imageUrls!.first,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _vehicle!.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _vehicle!.year,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _vehicle!.fuel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_vehicle!.mileage} km',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                _vehicle!.location,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard() {
    final theme = Theme.of(context);
    final currentValue = _vehicle!.salePrice > 0
        ? _vehicle!.salePrice * _investment!.investmentRatio
        : _investment!.amount;
    final profit = currentValue - _investment!.amount;
    final profitPercentage =
        _investment!.amount > 0 ? (profit / _investment!.amount * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profit Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Profit Received',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_investment!.totalProfitReceived.toStringAsFixed(0)} PKR',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.trending_up,
                  color: Color(0xFF4CAF50),
                  size: 32,
                ),
              ],
            ),
          ),
          if (_vehicle!.salePrice > 0) ...[
            const SizedBox(height: 16),
            _buildProfitRow(
              'Current Value',
              '${currentValue.toStringAsFixed(0)} PKR',
            ),
            Divider(color: theme.colorScheme.surfaceVariant),
            _buildProfitRow(
              'Unrealized Profit',
              '${profit.toStringAsFixed(0)} PKR (${profitPercentage.toStringAsFixed(2)}%)',
              valueColor: profit >= 0
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF44336),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfitRow(String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareManagementSection() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Share Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (!_investment!.sharesForSale && !_showShareListingForm)
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showShareListingForm = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.sell, size: 18, color: Colors.white),
                    label: const Text(
                      'Sell Shares',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_investment!.sharesForSale)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFF6B35),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shares Listed for Sale',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Asking Price: ${_investment!.sharesForSalePrice?.toStringAsFixed(0) ?? 'N/A'} PKR',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _investmentService
                          .cancelShareSale(widget.investmentId);
                      await _loadInvestment();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF44336),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            )
          else if (_showShareListingForm)
            ShareListingWidget(
              investment: _investment!,
              vehicle: _vehicle!,
              onListingComplete: () async {
                setState(() {
                  _showShareListingForm = false;
                });
                await _loadInvestment();
              },
              onCancel: () {
                setState(() {
                  _showShareListingForm = false;
                });
              },
            )
          else
            Text(
              'You can list your shares for sale on the marketplace.',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistorySection() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<InvestmentTransactionModel>>(
            stream:
                _transactionService.getUserTransactions(_auth.currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: theme.colorScheme.error),
                );
              }

              final transactions = snapshot.data ?? [];
              final investmentTransactions = transactions
                  .where((t) => t.investmentId == widget.investmentId)
                  .toList();

              if (investmentTransactions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: investmentTransactions.length,
                separatorBuilder: (context, index) => Divider(
                  color: theme.colorScheme.surfaceVariant,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final transaction = investmentTransactions[index];
                  return _buildTransactionItem(transaction);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(InvestmentTransactionModel transaction) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getTransactionColor(transaction.status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTransactionIcon(transaction.type),
              color: _getTransactionColor(transaction.status),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTransactionTypeName(transaction.type),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.amount.toStringAsFixed(0)} PKR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getTransactionColor(transaction.status)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transaction.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getTransactionColor(transaction.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitHistorySection() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profit Distribution History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<InvestmentTransactionModel>>(
            stream: _profitService.getUserProfitHistory(_auth.currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: theme.colorScheme.error),
                );
              }

              final profitTransactions = snapshot.data ?? [];
              final investmentProfits = profitTransactions
                  .where((t) => t.investmentId == widget.investmentId)
                  .toList();

              if (investmentProfits.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No profit distributions yet',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: investmentProfits.length,
                separatorBuilder: (context, index) => Divider(
                  color: theme.colorScheme.surfaceVariant,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final transaction = investmentProfits[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Color(0xFF4CAF50),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profit Distribution',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(transaction.distributionDate ??
                                    transaction.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${transaction.profitAmount?.toStringAsFixed(0) ?? transaction.amount.toStringAsFixed(0)} PKR',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'investment':
        return Icons.add_circle;
      case 'profit_distribution':
        return Icons.account_balance_wallet;
      case 'share_sale':
        return Icons.sell;
      case 'share_purchase':
        return Icons.shopping_cart;
      case 'refund':
        return Icons.undo;
      default:
        return Icons.receipt;
    }
  }

  Color _getTransactionColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTransactionTypeName(String type) {
    switch (type) {
      case 'investment':
        return 'Investment';
      case 'profit_distribution':
        return 'Profit Distribution';
      case 'share_sale':
        return 'Share Sale';
      case 'share_purchase':
        return 'Share Purchase';
      case 'refund':
        return 'Refund';
      default:
        return type;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'sold':
        return Colors.blue;
      case 'refunded':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
