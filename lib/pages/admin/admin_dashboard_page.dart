import 'package:carhive/models/ad_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

import 'admin_manage_users_page.dart';
import 'admin_system_analytics_page.dart';
import 'admin_view_all_ads_page.dart';
import 'admin_insight_metrics_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    final adminProvider = context.read<AdminProvider>();
    print('AdminDashboard: Loading all data.. .');

    // Load all data in parallel
    await Future.wait([
      adminProvider.loadDashboardStats(),
      adminProvider.loadRecentActivities(),
      adminProvider.loadPendingAds(),
    ]);

    print('AdminDashboard: All data loaded');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CarHive Admin Dashboard',
          style: TextStyle(
            color: isDark ? const Color(0xFFf48c25) : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFFf48c25) : Colors.black,
        ),
        actionsIconTheme: IconThemeData(
          color: isDark ? const Color(0xFFf48c25) : Colors.black,
        ),
        actions: [
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle),
                onSelected: (value) {
                  if (value == 'logout') {
                    adminProvider.adminLogout();
                    Navigator.pushReplacementNamed(context, '/admin/login');
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Text(
                            adminProvider.currentAdmin?.displayName ?? 'Admin'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = adminProvider.dashboardStats;
          if (stats == null) {
            return const Center(child: Text('Failed to load dashboard data'));
          }

          return RefreshIndicator(
            onRefresh: _loadAllData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${adminProvider.currentAdmin?.displayName ?? 'Admin'}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Here\'s what\'s happening with CarHive today',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Statistics Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        'Total Users',
                        stats.totalUsers.toString(),
                        Icons.people,
                        const Color(0xFFf48c25),
                      ),
                      _buildStatCard(
                        'Total Ads',
                        stats.totalAds.toString(),
                        Icons.car_rental,
                        const Color(0xFFf48c25),
                      ),
                      _buildStatCard(
                        'Pending Ads',
                        stats.pendingAds.toString(),
                        Icons.pending_actions,
                        const Color(0xFFFF6B35),
                      ),
                      _buildStatCard(
                        'Active Ads',
                        stats.activeAds.toString(),
                        Icons.check_circle,
                        const Color(0xFFf48c25),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pending Ads Section
                  _buildPendingAdsSection(),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          'Manage Users',
                          Icons.people_outline,
                          const Color(0xFFf48c25),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminManageUsersPage(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionCard(
                          'System Analytics',
                          Icons.analytics,
                          const Color(0xFFFF6B35),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminSystemAnalyticsPage(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          'View All Ads',
                          Icons.list_alt,
                          const Color(0xFFFF8C42),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminViewAllAdsPage(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionCard(
                          'Insight Metrics',
                          Icons.insights,
                          const Color(0xFF9C27B0),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminInsightMetricsPage(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Activity
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentActivityCard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    final gradient = LinearGradient(
      colors: [
        color.withOpacity(0.9),
        color.withOpacity(0.6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withOpacity(0.2),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingAdsSection() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final pendingAds = adminProvider.pendingAds;

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade50,
                  Colors.orange.shade100,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.pending_actions,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Ads Review',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            Text(
                              '${pendingAds.length} ads waiting for approval',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Refresh Button
                      IconButton(
                        onPressed: () {
                          print('AdminDashboard: Refreshing pending ads...');
                          adminProvider.loadPendingAds();
                        },
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.orange.shade600,
                        ),
                        tooltip: 'Refresh pending ads',
                      ),
                      // Debug Button
                      IconButton(
                        onPressed: () {
                          print('AdminDashboard:  Debugging ad statuses...');
                          adminProvider.debugAndFixAdStatuses();
                        },
                        icon: Icon(
                          Icons.bug_report,
                          color: Colors.red.shade600,
                        ),
                        tooltip: 'Debug ad statuses',
                      ),
                      if (pendingAds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${pendingAds.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Debug Info (temporary)
                  if (kDebugMode)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Debug Info: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text('Loading: ${adminProvider.isLoading}'),
                          Text('Pending Ads Count: ${pendingAds.length}'),
                          Text(
                              'Error:  ${adminProvider.errorMessage ?? 'None'}'),
                        ],
                      ),
                    ),

                  // Pending Ads List
                  if (adminProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (pendingAds.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Pending Ads',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All ads have been reviewed! ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: pendingAds.take(3).map((ad) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Car Icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Ad Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ad.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${ad.price} • ${ad.location}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${ad.year} • ${ad.mileage} km',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Action Buttons
                              Column(
                                children: [
                                  // Approve Button
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade500,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      onPressed: () => _approveAd(ad),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Reject Button
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade500,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      onPressed: () => _rejectAd(ad),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  // View All Button
                  if (pendingAds.length > 3)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/admin/ads'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.visibility, size: 18),
                          label:
                              Text('View All ${pendingAds.length} Pending Ads'),
                        ),
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

  Future<void> _approveAd(AdModel ad) async {
    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.approveAd(ad.id!);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ad "${ad.title}" approved successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve ad'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _rejectAd(AdModel ad) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Ad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject "${ad.title}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final adminProvider = context.read<AdminProvider>();
      final success = await adminProvider.rejectAd(ad.id!, result);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ad "${ad.title}" rejected'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject ad'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildRecentActivityCard() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final activities = adminProvider.recentActivities;

        if (activities.isEmpty) {
          return Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No recent activities',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: activities.map((activity) {
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: activity.color,
                        child: Icon(activity.icon, color: Colors.white),
                      ),
                      title: Text(activity.title),
                      subtitle: Text(activity.description),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Handle activity tap - could show details or navigate
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Activity: ${activity.title}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    if (activity != activities.last) const Divider(),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
