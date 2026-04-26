import 'package:carhive/models/ad_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import 'admin_insight_metrics_page.dart';
import 'admin_system_analytics_page.dart';
import 'admin_users_page.dart';
import 'admin_view_all_ads_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const Color _accent = Color(0xFFf48c25);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    final adminProvider = context.read<AdminProvider>();
    await Future.wait([
      adminProvider.loadDashboardStats(),
      adminProvider.loadRecentActivities(),
      adminProvider.loadPendingAds(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CarHive Admin Dashboard',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.brightness == Brightness.dark
                ? _accent
                : colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await adminProvider.adminLogout();
                    if (!context.mounted) return;
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
                          adminProvider.currentAdmin?.displayName ?? 'Admin',
                        ),
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
          if (adminProvider.isLoading && adminProvider.dashboardStats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = adminProvider.dashboardStats;
          if (stats == null) {
            return const Center(child: Text('Failed to load dashboard data'));
          }

          return RefreshIndicator(
            onRefresh: _loadAllData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeBanner(context, adminProvider),
                  const SizedBox(height: 20),
                  _buildStatsGrid(
                    context,
                    stats: stats,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildQuickActionsGrid(context),
                  const SizedBox(height: 24),
                  _buildPendingAdsSection(),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Activity',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildRecentActivityCard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeBanner(
    BuildContext context,
    AdminProvider adminProvider,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${adminProvider.currentAdmin?.displayName ?? 'Admin'}!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Here\'s what needs your attention across CarHive today.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context, {
    required dynamic stats,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1400
            ? 4
            : width >= 900
                ? 2
                : 1;
        final aspectRatio = width >= 1400
            ? 2.3
            : width >= 900
                ? 2.0
                : 2.2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: aspectRatio,
          children: [
            _buildStatCard(
              'Total Users',
              stats.totalUsers.toString(),
              Icons.people_outline,
              trendLabel: 'Healthy growth',
              isPositive: true,
            ),
            _buildStatCard(
              'Total Ads',
              stats.totalAds.toString(),
              Icons.directions_car_outlined,
              trendLabel: 'Inventory count',
              isPositive: true,
            ),
            _buildStatCard(
              'Pending Ads',
              stats.pendingAds.toString(),
              Icons.pending_actions_outlined,
              trendLabel: 'Needs review',
              isPositive: false,
            ),
            _buildStatCard(
              'Active Ads',
              stats.activeAds.toString(),
              Icons.check_circle_outline,
              trendLabel: 'Currently live',
              isPositive: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    required String trendLabel,
    required bool isPositive,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: _dashboardCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: double.infinity,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: isPositive ? Colors.green : const Color(0xFFFF6B35),
                ),
                const SizedBox(height: 4),
                Text(
                  trendLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    const actions = [
      _DashboardQuickAction(
        title: 'Manage Users',
        description: 'Review user accounts, roles, and access.',
        icon: Icons.people_outline,
      ),
      _DashboardQuickAction(
        title: 'System Analytics',
        description: 'Check platform health and operational signals.',
        icon: Icons.analytics_outlined,
      ),
      _DashboardQuickAction(
        title: 'View All Ads',
        description: 'Browse approved, pending, and archived ads.',
        icon: Icons.list_alt_outlined,
      ),
      _DashboardQuickAction(
        title: 'Insight Metrics',
        description: 'Monitor views, messages, and market trends.',
        icon: Icons.insights_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 4
            : width >= 700
                ? 2
                : 1;
        final aspectRatio = width >= 1100
            ? 1.7
            : width >= 700
                ? 2.0
                : 2.45;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: aspectRatio,
          children: actions.map((action) {
            return _buildActionCard(
              title: action.title,
              description: action.description,
              icon: action.icon,
              onTap: () => _openQuickAction(action.title),
            );
          }).toList(),
        );
      },
    );
  }

  void _openQuickAction(String title) {
    switch (title) {
      case 'Manage Users':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminUsersPage()),
        );
        return;
      case 'System Analytics':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminSystemAnalyticsPage()),
        );
        return;
      case 'View All Ads':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminViewAllAdsPage()),
        );
        return;
      case 'Insight Metrics':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminInsightMetricsPage()),
        );
        return;
    }
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: _dashboardCardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: _accent),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Open',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: _accent),
                  ],
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
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          decoration: _dashboardCardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.pending_actions_outlined,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending Ads Review',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pendingAds.length} ads waiting for approval',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: adminProvider.loadPendingAds,
                      icon: const Icon(Icons.refresh, color: _accent),
                      tooltip: 'Refresh pending ads',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (adminProvider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (pendingAds.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 44,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No Pending Ads',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All ads have been reviewed.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.directions_car_outlined,
                                color: _accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ad.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${ad.price} • ${ad.location}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${ad.year} • ${ad.mileage} km',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              children: [
                                _decisionButton(
                                  icon: Icons.check,
                                  color: Colors.green,
                                  onTap: () => _approveAd(ad),
                                ),
                                const SizedBox(height: 8),
                                _decisionButton(
                                  icon: Icons.close,
                                  color: Colors.red,
                                  onTap: () => _rejectAd(ad),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                if (pendingAds.length > 3) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/admin/ads'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: Text('View All ${pendingAds.length} Pending Ads'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _decisionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Future<void> _approveAd(AdModel ad) async {
    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.approveAd(ad.id!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Ad "${ad.title}" approved successfully'
              : 'Failed to approve ad',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
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

    if (result == null || !mounted) {
      return;
    }

    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.rejectAd(ad.id!, result);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Ad "${ad.title}" rejected' : 'Failed to reject ad',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        if (adminProvider.isLoading) {
          return Container(
            decoration: _dashboardCardDecoration(context),
            padding: const EdgeInsets.all(20),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final activities = adminProvider.recentActivities;
        if (activities.isEmpty) {
          return Container(
            decoration: _dashboardCardDecoration(context),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No recent activities',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return Container(
          decoration: _dashboardCardDecoration(context),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: activities.map((activity) {
              final isLast = activity == activities.last;
              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: activity.color,
                      child: Icon(activity.icon, color: Colors.white),
                    ),
                    title: Text(
                      activity.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      activity.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Activity: ${activity.title}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  BoxDecoration _dashboardCardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.45),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class _DashboardQuickAction {
  const _DashboardQuickAction({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
