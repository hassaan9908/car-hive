import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/custom_bottom_nav.dart';
import '../services/investment_vehicle_service.dart';
import '../services/investment_service.dart';
import '../models/investment_vehicle_model.dart';
import '../models/investment_model.dart';
import 'investment_detail_page.dart';
import 'create_investment_page.dart';
import 'share_marketplace_page.dart';
import 'my_investment_detail_page.dart';

class Mutualinvestment extends StatefulWidget {
  const Mutualinvestment({super.key});

  @override
  State<Mutualinvestment> createState() => _MutualinvestmentState();
}

class _MutualinvestmentState extends State<Mutualinvestment>
    with SingleTickerProviderStateMixin {
  static const int _selectedIndex = 3;
  static const List<String> _navRoutes = [
    '/',
    '/myads',
    '/upload',
    '/investment',
    '/profile'
  ];

  late TabController _tabController;
  final InvestmentVehicleService _vehicleService = InvestmentVehicleService();
  final InvestmentService _investmentService = InvestmentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabSelected(BuildContext context, int index) {
    if (_selectedIndex == index) return;
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
          context, _navRoutes[0], (route) => false);
    } else {
      Navigator.pushReplacementNamed(context, _navRoutes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mutual Investment'),
              backgroundColor: Colors.transparent,
              centerTitle: true,
          actions: [
            if (user != null)
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateInvestmentPage(),
                    ),
                  );
                  if (result != null && mounted) {
                    // Investment created, could navigate to detail page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Investment opportunity created!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                tooltip: 'Create Investment',
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Available', icon: Icon(Icons.search)),
              Tab(text: 'My Investments', icon: Icon(Icons.account_balance)),
              Tab(text: 'Marketplace', icon: Icon(Icons.store)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Available Investments Tab
            _buildAvailableInvestmentsTab(),
            // My Investments Tab
            user != null
                ? _buildMyInvestmentsTab(user.uid)
                : const Center(
                    child: Text('Please login to view your investments')),
            // Marketplace Tab
            _buildMarketplaceTab(),
          ],
        ),
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTabSelected: (index) => _onTabSelected(context, index),
          onFabPressed: () {
            if (_selectedIndex != 2) {
              Navigator.pushReplacementNamed(context, _navRoutes[2]);
            }
          },
        ),
      ),
    );
  }

  Widget _buildAvailableInvestmentsTab() {
    return StreamBuilder<List<InvestmentVehicleModel>>(
      stream: _vehicleService.getOpenInvestmentVehicles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final vehicles = snapshot.data ?? [];

        if (vehicles.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No investment opportunities available',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            return _buildInvestmentVehicleCard(vehicle);
          },
        );
      },
    );
  }

  Widget _buildMyInvestmentsTab(String userId) {
    return StreamBuilder<List<InvestmentModel>>(
      stream: _investmentService.getUserActiveInvestments(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final investments = snapshot.data ?? [];

        if (investments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'You have no active investments',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: investments.length,
          itemBuilder: (context, index) {
            final investment = investments[index];
            return _buildMyInvestmentCard(investment);
          },
        );
      },
    );
  }

  Widget _buildMarketplaceTab() {
    return ShareMarketplacePage();
  }

  Widget _buildInvestmentVehicleCard(InvestmentVehicleModel vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvestmentDetailPage(
                vehicleInvestmentId: vehicle.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Image
              if (vehicle.imageUrls != null && vehicle.imageUrls!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    vehicle.imageUrls!.first,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 64),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              // Title
              Text(
                vehicle.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Vehicle Details
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${vehicle.year}'),
                  const SizedBox(width: 16),
                  Icon(Icons.local_gas_station,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(vehicle.fuel),
                  const SizedBox(width: 16),
                  Icon(Icons.speed, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${vehicle.mileage} km'),
                ],
              ),
              const SizedBox(height: 12),
              // Investment Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Investment Goal: ${vehicle.totalInvestmentGoal.toStringAsFixed(0)} PKR',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${vehicle.fundingProgress.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: vehicle.fundingProgress / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Invested: ${vehicle.currentInvestment.toStringAsFixed(0)} PKR / Remaining: ${vehicle.remainingAmount.toStringAsFixed(0)} PKR',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Minimum Contribution
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Minimum: ${vehicle.minimumContribution.toStringAsFixed(0)} PKR',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyInvestmentCard(InvestmentModel investment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Investment #${investment.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    '${(investment.investmentRatio * 100).toStringAsFixed(2)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.green[100],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ${investment.amount.toStringAsFixed(0)} PKR',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Profit Received: ${investment.totalProfitReceived.toStringAsFixed(0)} PKR',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyInvestmentDetailPage(
                          investmentId: investment.id,
                        ),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}