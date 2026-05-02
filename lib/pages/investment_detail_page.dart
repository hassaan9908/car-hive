import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/investment_vehicle_model.dart';
import '../models/share_marketplace_model.dart';
import '../services/investment_vehicle_service.dart';
import '../services/share_marketplace_service.dart';
import '../widgets/investment_form_widget.dart';
import 'share_marketplace_page.dart';

class InvestmentDetailPage extends StatefulWidget {
  final String vehicleInvestmentId;

  const InvestmentDetailPage({
    super.key,
    required this.vehicleInvestmentId,
  });

  @override
  State<InvestmentDetailPage> createState() => _InvestmentDetailPageState();
}

class _InvestmentDetailPageState extends State<InvestmentDetailPage> {
  final InvestmentVehicleService _vehicleService = InvestmentVehicleService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  InvestmentVehicleModel? _vehicle;
  bool _isLoading = true;
  bool _showInvestmentForm = false;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    try {
      final vehicle = await _vehicleService
          .getInvestmentVehicleById(widget.vehicleInvestmentId);
      if (mounted) {
        setState(() {
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
          SnackBar(content: Text('Error loading vehicle: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Investment Details'),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_vehicle == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Investment Details'),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: Text('Investment vehicle not found'),
        ),
      );
    }

    final user = _auth.currentUser;
    final canInvest = user != null &&
        _vehicle!.investmentStatus == 'open' &&
        !_vehicle!.isExpired &&
        !_vehicle!.isFullyFunded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Details'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Images
            if (_vehicle!.imageUrls != null && _vehicle!.imageUrls!.isNotEmpty)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: PageView.builder(
                  itemCount: _vehicle!.imageUrls!.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      _vehicle!.imageUrls![index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 64),
                        );
                      },
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _vehicle!.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Vehicle Details
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDetailChip(
                        Icons.calendar_today,
                        _vehicle!.year,
                      ),
                      _buildDetailChip(
                        Icons.local_gas_station,
                        _vehicle!.fuel,
                      ),
                      _buildDetailChip(
                        Icons.speed,
                        '${_vehicle!.mileage} km',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _vehicle!.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Investment Status Card
                  _buildStatusCard(),
                  const SizedBox(height: 24),

                  // Investment Progress
                  _buildProgressSection(),
                  const SizedBox(height: 24),

                  // Investment Details
                  _buildInvestmentDetailsSection(),
                  const SizedBox(height: 24),

                  // Description
                  if (_vehicle!.description != null &&
                      _vehicle!.description!.isNotEmpty)
                    _buildDescriptionSection(),

                  const SizedBox(height: 24),

                  // Share Marketplace Section
                  if (_vehicle!.investmentStatus == 'funded' ||
                      _vehicle!.investmentStatus == 'open')
                    _buildShareMarketplaceSection(),

                  const SizedBox(height: 24),

                  // Investment Form or Button
                  if (canInvest)
                    _showInvestmentForm
                        ? InvestmentFormWidget(
                            vehicle: _vehicle!,
                            onInvestmentComplete: () {
                              setState(() {
                                _showInvestmentForm = false;
                              });
                              _loadVehicle(); // Reload to update progress
                            },
                            onCancel: () {
                              setState(() {
                                _showInvestmentForm = false;
                              });
                            },
                          )
                        : Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showInvestmentForm = true;
                                });
                              },
                              icon: const Icon(Icons.add_circle,
                                  color: Colors.white),
                              label: const Text(
                                'Invest Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          )
                  else
                    _buildCannotInvestMessage(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final theme = Theme.of(context);
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_vehicle!.investmentStatus) {
      case 'open':
        statusColor = Colors.blue;
        statusText = 'Open for Investment';
        statusIcon = Icons.lock_open;
        break;
      case 'funded':
        statusColor = const Color(0xFF4CAF50);
        statusText = 'Fully Funded';
        statusIcon = Icons.check_circle;
        break;
      case 'closed':
        statusColor = Colors.grey;
        statusText = 'Closed';
        statusIcon = Icons.lock;
        break;
      case 'sold':
        statusColor = const Color(0xFFFF6B35);
        statusText = 'Sold';
        statusIcon = Icons.sell;
        break;
      default:
        statusColor = Colors.grey;
        statusText = _vehicle!.investmentStatus;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (_vehicle!.expiresAt != null)
                  Text(
                    'Expires: ${_formatDate(_vehicle!.expiresAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                'Investment Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${_vehicle!.fundingProgress.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _vehicle!.fundingProgress / 100,
              minHeight: 12,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invested',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_vehicle!.currentInvestment.toStringAsFixed(0)} PKR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Goal',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_vehicle!.totalInvestmentGoal.toStringAsFixed(0)} PKR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Remaining: ${_vehicle!.remainingAmount.toStringAsFixed(0)} PKR',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentDetailsSection() {
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
            'Investment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Total Investment Goal',
            '${_vehicle!.totalInvestmentGoal.toStringAsFixed(0)} PKR',
          ),
          Divider(color: theme.colorScheme.surfaceVariant),
          _buildDetailRow(
            'Minimum Contribution',
            '${_vehicle!.minimumContribution.toStringAsFixed(0)} PKR',
          ),
          Divider(color: theme.colorScheme.surfaceVariant),
          _buildDetailRow(
            'Profit Distribution',
            'Proportional (Based on investment ratio)',
          ),
          Divider(color: theme.colorScheme.surfaceVariant),
          _buildDetailRow(
            'Platform Fee',
            '${_vehicle!.platformFeePercentage}%',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
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
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _vehicle!.description!,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCannotInvestMessage() {
    final theme = Theme.of(context);
    String message;
    if (_vehicle!.investmentStatus == 'funded') {
      message = 'This investment is fully funded';
    } else if (_vehicle!.investmentStatus == 'closed') {
      message = 'This investment is closed';
    } else if (_vehicle!.investmentStatus == 'sold') {
      message = 'This vehicle has been sold';
    } else if (_vehicle!.isExpired) {
      message = 'This investment opportunity has expired';
    } else {
      message = 'Please login to invest';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareMarketplaceSection() {
    final ShareMarketplaceService marketplaceService =
        ShareMarketplaceService();

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
                  'Share Marketplace',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShareMarketplacePage(
                          vehicleInvestmentId: widget.vehicleInvestmentId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ShareMarketplaceModel>>(
              stream: marketplaceService.getShareListingsForVehicle(
                widget.vehicleInvestmentId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final listings = snapshot.data ?? [];

                if (listings.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No shares available for purchase',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: listings.length > 3 ? 3 : listings.length,
                      itemBuilder: (context, index) {
                        final listing = listings[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.account_balance_wallet),
                            title: Text(
                              '${listing.sharePercentage.toStringAsFixed(2)}% Share',
                            ),
                            subtitle: Text(
                              'Asking: ${listing.askingPrice.toStringAsFixed(0)} PKR',
                            ),
                            trailing: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShareMarketplacePage(
                                      vehicleInvestmentId:
                                          widget.vehicleInvestmentId,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('View'),
                            ),
                          ),
                        );
                      },
                    ),
                    if (listings.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShareMarketplacePage(
                                    vehicleInvestmentId:
                                        widget.vehicleInvestmentId,
                                  ),
                                ),
                              );
                            },
                            child: Text('View All ${listings.length} Listings'),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
