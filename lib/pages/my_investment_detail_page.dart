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
  final ProfitDistributionService _profitService =
      ProfitDistributionService();
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
            if (_investment!.status == 'active')
              _buildShareManagementSection(),
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Investment Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Investment Amount', '${_investment!.amount.toStringAsFixed(0)} PKR'),
            const Divider(),
            _buildSummaryRow('Ownership Share', '${(_investment!.investmentRatio * 100).toStringAsFixed(2)}%'),
            const Divider(),
            _buildSummaryRow('Investment Date', _formatDate(_investment!.investmentDate)),
            const Divider(),
            _buildSummaryRow('Status', _investment!.status.toUpperCase(),
                valueColor: _getStatusColor(_investment!.status)),
            if (_vehicle!.salePrice > 0) ...[
              const Divider(),
              _buildSummaryRow('Current Vehicle Value', '${_vehicle!.salePrice.toStringAsFixed(0)} PKR',
                  valueColor: Colors.green),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_vehicle!.imageUrls != null && _vehicle!.imageUrls!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _vehicle!.imageUrls!.first,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 64),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Text(
              _vehicle!.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(_vehicle!.year)),
                const SizedBox(width: 8),
                Chip(label: Text(_vehicle!.fuel)),
                const SizedBox(width: 8),
                Chip(label: Text('${_vehicle!.mileage} km')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Text(_vehicle!.location),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitCard() {
    final currentValue = _vehicle!.salePrice > 0
        ? _vehicle!.salePrice * _investment!.investmentRatio
        : _investment!.amount;
    final profit = currentValue - _investment!.amount;
    final profitPercentage = _investment!.amount > 0
        ? (profit / _investment!.amount * 100)
        : 0.0;

    return Card(
      elevation: 2,
      color: profit >= 0 ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profit Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Profit Received:'),
                Text(
                  '${_investment!.totalProfitReceived.toStringAsFixed(0)} PKR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            if (_vehicle!.salePrice > 0) ...[
              const SizedBox(height: 12),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Value:'),
                  Text(
                    '${currentValue.toStringAsFixed(0)} PKR',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Unrealized Profit:'),
                  Text(
                    '${profit.toStringAsFixed(0)} PKR (${profitPercentage.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: profit >= 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShareManagementSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_investment!.sharesForSale && !_showShareListingForm)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showShareListingForm = true;
                      });
                    },
                    icon: const Icon(Icons.sell),
                    label: const Text('Sell Shares'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_investment!.sharesForSale)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shares Listed for Sale',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Asking Price: ${_investment!.sharesForSalePrice?.toStringAsFixed(0) ?? 'N/A'} PKR',
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _investmentService.cancelShareSale(widget.investmentId);
                        await _loadInvestment();
                      },
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
              const Text(
                'You can list your shares for sale on the marketplace.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistorySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<InvestmentTransactionModel>>(
              stream: _transactionService.getUserTransactions(_auth.currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final transactions = snapshot.data ?? [];
                final investmentTransactions = transactions
                    .where((t) => t.investmentId == widget.investmentId)
                    .toList();

                if (investmentTransactions.isEmpty) {
                  return const Text('No transactions found');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: investmentTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = investmentTransactions[index];
                    return _buildTransactionItem(transaction);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(InvestmentTransactionModel transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getTransactionIcon(transaction.type),
          color: _getTransactionColor(transaction.status),
        ),
        title: Text(_getTransactionTypeName(transaction.type)),
        subtitle: Text(_formatDate(transaction.createdAt)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaction.amount.toStringAsFixed(0)} PKR',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              transaction.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: _getTransactionColor(transaction.status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitHistorySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profit Distribution History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<InvestmentTransactionModel>>(
              stream: _profitService.getUserProfitHistory(_auth.currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final profitTransactions = snapshot.data ?? [];
                final investmentProfits = profitTransactions
                    .where((t) => t.investmentId == widget.investmentId)
                    .toList();

                if (investmentProfits.isEmpty) {
                  return const Text('No profit distributions yet');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: investmentProfits.length,
                  itemBuilder: (context, index) {
                    final transaction = investmentProfits[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.green[50],
                      child: ListTile(
                        leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
                        title: const Text('Profit Distribution'),
                        subtitle: Text(_formatDate(transaction.distributionDate ?? transaction.createdAt)),
                        trailing: Text(
                          '+${transaction.profitAmount?.toStringAsFixed(0) ?? transaction.amount.toStringAsFixed(0)} PKR',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
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

