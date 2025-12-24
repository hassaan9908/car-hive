import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'all';
  String _statusFilter = 'all';
  String _sortBy = 'name';
  int? _dateFilterDays; // null = all time, 7/30/90 for recent joins
  bool _selectionMode = false;
  final Set<String> _selectedUserIds = <String>{};
  String _bulkRole = 'user';
  bool _isBulkWorking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load a larger batch to support stats and growth chart
      context.read<AdminProvider>().loadUsers(limit: 500);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.displayName ?? user.email),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Display Name', user.displayName ?? 'N/A'),
              _buildDetailRow('Phone', user.phoneNumber ?? 'N/A'),
              _buildDetailRow('Role', user.role),
              _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Joined', _formatDate(user.createdAt)),
              _buildDetailRow('Last Login', _formatDate(user.lastLoginAt)),
              const SizedBox(height: 16),
              const Text(
                'Ad Statistics:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                  'Total Ads Posted', user.totalAdsPosted.toString()),
              _buildDetailRow('Active Ads', user.activeAdsCount.toString()),
              _buildDetailRow('Rejected Ads', user.rejectedAdsCount.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRoleUpdateDialog(UserModel user) {
    String selectedRole = user.role;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update User Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Update role for ${user.displayName ?? user.email}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(
                      value: 'super_admin', child: Text('Super Admin')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success =
                    await context.read<AdminProvider>().updateUserRole(
                          user.id,
                          selectedRole,
                        );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('User role updated successfully')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusToggleDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'Deactivate User' : 'Activate User'),
        content: Text(
          user.isActive
              ? 'Are you sure you want to deactivate ${user.displayName ?? user.email}?'
              : 'Are you sure you want to activate ${user.displayName ?? user.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await context.read<AdminProvider>().toggleUserStatus(
                        user.id,
                        !user.isActive,
                      );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      user.isActive
                          ? 'User deactivated successfully'
                          : 'User activated successfully',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red : Colors.green,
            ),
            child: Text(user.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardGradient = LinearGradient(
      colors: isDark
          ? [const Color(0xFF111827), const Color(0xFF0B1220)]
          : [Colors.grey.shade100, Colors.grey.shade200],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final borderColor =
        isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade400;

    final pageBackground = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0B1220), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : LinearGradient(
            colors: [Colors.grey.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: pageBackground),
        child: Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            final allUsers = adminProvider.users;

            if (adminProvider.isLoading && allUsers.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final filtered = _applyFilters(allUsers);

            return Column(
              children: [
                _buildSearchAndFilters(cardGradient, borderColor, isDark),
                if (_selectionMode)
                  _buildBulkActionsBar(cardGradient, borderColor, isDark),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final user = filtered[index];
                            final selected = _selectedUserIds.contains(user.id);
                            final lastLoginDelta =
                                DateTime.now().difference(user.lastLoginAt);
                            final recentlyActive = lastLoginDelta.inHours < 24;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                gradient: cardGradient,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 95,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFF48C25),
                                          const Color(0xFFFFB56B),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ListTile(
                                      onLongPress: () =>
                                          _toggleSelectionMode(user.id),
                                      onTap: _selectionMode
                                          ? () => _toggleUserSelected(user.id)
                                          : null,
                                      contentPadding: const EdgeInsets.fromLTRB(
                                          12, 14, 12, 14),
                                      leading: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_selectionMode)
                                            Checkbox(
                                              value: selected,
                                              onChanged: (_) =>
                                                  _toggleUserSelected(user.id),
                                            ),
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor:
                                                _getRoleColor(user.role)
                                                    .withOpacity(0.18),
                                            child: CircleAvatar(
                                              radius: 18,
                                              backgroundColor:
                                                  _getRoleColor(user.role),
                                              child: Text(
                                                (user.displayName?.isNotEmpty ==
                                                            true
                                                        ? user.displayName![0]
                                                        : user.email[0])
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      title: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              user.displayName ?? 'No Name',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _buildBadge(
                                                label: user.role
                                                    .replaceAll('_', ' ')
                                                    .toUpperCase(),
                                                color: _getRoleColor(user.role),
                                              ),
                                              const SizedBox(width: 8),
                                              _buildBadge(
                                                label: user.isActive
                                                    ? 'ACTIVE'
                                                    : 'INACTIVE',
                                                color: user.isActive
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                              const SizedBox(width: 8),
                                              _buildBadge(
                                                label:
                                                    'Ads: ${user.totalAdsPosted}',
                                                color: Colors.blueGrey,
                                              ),
                                              if (recentlyActive) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: const [
                                                      Icon(Icons.bolt,
                                                          size: 13,
                                                          color: Colors.green),
                                                      SizedBox(width: 3),
                                                      Text(
                                                        'Active',
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.green,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                user.email,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade500,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '•',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.schedule,
                                                  size: 13,
                                                  color: Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  _formatDate(user.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade500,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: _selectionMode
                                          ? null
                                          : PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert),
                                              onSelected: (value) {
                                                switch (value) {
                                                  case 'details':
                                                    _showUserDetails(user);
                                                    break;
                                                  case 'role':
                                                    _showRoleUpdateDialog(user);
                                                    break;
                                                  case 'toggle_status':
                                                    _showStatusToggleDialog(
                                                        user);
                                                    break;
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'details',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.info_outline),
                                                      SizedBox(width: 8),
                                                      Text('View Details'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'role',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons
                                                          .admin_panel_settings),
                                                      SizedBox(width: 8),
                                                      Text('Update Role'),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'toggle_status',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        user.isActive
                                                            ? Icons.block
                                                            : Icons
                                                                .check_circle,
                                                        color: user.isActive
                                                            ? Colors.red
                                                            : Colors.green,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(user.isActive
                                                          ? 'Deactivate'
                                                          : 'Activate'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryStrip(List<UserModel> users, LinearGradient cardGradient,
      Color borderColor, bool isDark) {
    final total = users.length;
    final active = users.where((u) => u.isActive).length;
    final admins = users.where((u) => u.role == 'admin').length;
    final supers = users.where((u) => u.role == 'super_admin').length;
    final recent30 = users
        .where((u) => DateTime.now().difference(u.createdAt).inDays <= 30)
        .length;
    final activePercent =
        total > 0 ? ((active / total) * 100).toStringAsFixed(1) : '0';

    final cards = [
      _summaryCard(
        title: 'Total Users',
        value: total.toString(),
        icon: Icons.people,
        gradient: cardGradient,
        borderColor: borderColor,
        accentColor: const Color(0xFFF48C25),
        subtitle: 'All registered users',
      ),
      _summaryCard(
        title: 'Active Users',
        value: active.toString(),
        icon: Icons.verified_user,
        gradient: cardGradient,
        borderColor: borderColor,
        accentColor: Colors.green,
        subtitle: '$activePercent% activity rate',
      ),
      _summaryCard(
        title: 'New (30d)',
        value: recent30.toString(),
        icon: Icons.trending_up,
        gradient: cardGradient,
        borderColor: borderColor,
        accentColor: Colors.deepOrange,
        subtitle: 'Last 30 days',
      ),
      _summaryCard(
        title: 'Admins',
        value: '${admins + supers}',
        icon: Icons.admin_panel_settings,
        gradient: cardGradient,
        borderColor: borderColor,
        accentColor: Colors.blue,
        subtitle: '$admins admin + $supers super',
      ),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => SizedBox(width: 190, child: cards[i]),
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemCount: cards.length,
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
    required Color borderColor,
    required Color accentColor,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: accentColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(List<UserModel> users, LinearGradient cardGradient,
      Color borderColor, bool isDark) {
    if (users.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final buckets = List.generate(8, (i) {
      final end = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i * 7));
      final start = end.subtract(const Duration(days: 6));
      return {'label': 'W${8 - i}', 'start': start, 'end': end, 'count': 0};
    }).reversed.toList();

    for (final user in users) {
      for (final bucket in buckets) {
        final start = bucket['start'] as DateTime;
        final end = bucket['end'] as DateTime;
        if (user.createdAt.isAfter(start.subtract(const Duration(days: 1))) &&
            user.createdAt.isBefore(end.add(const Duration(days: 1)))) {
          bucket['count'] = (bucket['count'] as int) + 1;
          break;
        }
      }
    }

    final maxCount = buckets.fold<int>(
        1, (m, b) => (b['count'] as int) > m ? b['count'] as int : m);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Growth Analytics',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last 8 weeks performance',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF48C25).withOpacity(0.2),
                      const Color(0xFFFFB56B).withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF48C25).withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Colors.deepOrange,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${buckets.last['count']} this week',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= buckets.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            buckets[index]['label'] as String,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  buckets.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (buckets[i]['count'] as int).toDouble(),
                        width: 18,
                        color: const Color(0xFFF48C25),
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxCount.toDouble(),
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
      LinearGradient cardGradient, Color borderColor, bool isDark) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: cardGradient,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search users by email, name, or phone...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        splashRadius: 24,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: const Color(0xFFF48C25).withOpacity(0.6),
                      width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                filled: false,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
        // Filter chips and sort
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Row(
            children: [
              // Role dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Filter by Role',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _roleFilter == 'all'
                              ? Colors.grey.shade400
                              : const Color(0xFFF48C25).withOpacity(0.4),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: _roleFilter == 'all'
                            ? Colors.transparent
                            : const Color(0xFFF48C25).withOpacity(0.06),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: DropdownButton<String>(
                        value: _roleFilter,
                        onChanged: (v) =>
                            setState(() => _roleFilter = v ?? 'all'),
                        underline: const SizedBox(),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Text(
                                'All Roles',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _roleFilter == 'all'
                                      ? const Color(0xFFF48C25)
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'user',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Text(
                                'User',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _roleFilter == 'user'
                                      ? const Color(0xFFF48C25)
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _roleFilter == 'admin'
                                      ? const Color(0xFFF48C25)
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'super_admin',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Text(
                                'Super Admin',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _roleFilter == 'super_admin'
                                      ? const Color(0xFFF48C25)
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Status dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Filter by Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _statusFilter == 'all'
                              ? Colors.grey.shade400
                              : const Color(0xFFF48C25).withOpacity(0.4),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: _statusFilter == 'all'
                            ? Colors.transparent
                            : const Color(0xFFF48C25).withOpacity(0.06),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        onChanged: (v) =>
                            setState(() => _statusFilter = v ?? 'all'),
                        underline: const SizedBox(),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Text(
                                'Any Status',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _statusFilter == 'all'
                                      ? const Color(0xFFF48C25)
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _statusFilter == 'active'
                                      ? const Color(0xFFF48C25)
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Text(
                                'Inactive',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _statusFilter == 'inactive'
                                      ? const Color(0xFFF48C25)
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Date dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Join Date',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: (_dateFilterDays == null)
                              ? Colors.grey.shade400
                              : const Color(0xFFF48C25).withOpacity(0.4),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: (_dateFilterDays == null)
                            ? Colors.transparent
                            : const Color(0xFFF48C25).withOpacity(0.06),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: DropdownButton<String>(
                        value: _dateFilterDays?.toString() ?? 'all',
                        onChanged: (v) {
                          setState(() {
                            if (v == 'all') {
                              _dateFilterDays = null;
                            } else {
                              _dateFilterDays = int.parse(v ?? '7');
                            }
                          });
                        },
                        underline: const SizedBox(),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Text(
                                'All Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _dateFilterDays == null
                                      ? const Color(0xFFF48C25)
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '7',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Text(
                                'Last 7 days',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _dateFilterDays == 7
                                      ? const Color(0xFFF48C25)
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '30',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Text(
                                'Last 30 days',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _dateFilterDays == 30
                                      ? const Color(0xFFF48C25)
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '90',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Text(
                                'Last 90 days',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _dateFilterDays == 90
                                      ? const Color(0xFFF48C25)
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          thickness: 0.8,
          height: 1,
          indent: 24,
          endIndent: 24,
        ),
      ],
    );
  }

  Widget _filterChip(
      String label, String value, String group, ValueChanged<String> onTap) {
    final isSelected = value == group;
    return SizedBox(
      height: 36,
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(value),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        selectedColor: const Color(0xFFF48C25).withOpacity(0.15),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFFF48C25) : Colors.grey.shade700,
        ),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFFF48C25).withOpacity(0.4)
              : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildBulkActionsBar(
      LinearGradient cardGradient, Color borderColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('${_selectedUserIds.length} selected'),
              const Spacer(),
              TextButton(
                onPressed: _isBulkWorking ? null : () => _bulkSetActive(true),
                child: const Text('Activate'),
              ),
              TextButton(
                onPressed: _isBulkWorking ? null : () => _bulkSetActive(false),
                child: const Text('Deactivate'),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Set role:'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _bulkRole,
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(
                      value: 'super_admin', child: Text('Super Admin')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _bulkRole = val);
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _isBulkWorking ? null : () => _bulkSetRole(_bulkRole),
                child: _isBulkWorking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No users found'
                : 'No users found with current filters',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  List<UserModel> _applyFilters(List<UserModel> users) {
    var list = users.where((user) {
      final matchesSearch = _searchQuery.isEmpty
          ? true
          : user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (user.displayName?.toLowerCase() ?? '')
                  .contains(_searchQuery.toLowerCase()) ||
              (user.phoneNumber?.toLowerCase() ?? '')
                  .contains(_searchQuery.toLowerCase());

      final matchesRole =
          _roleFilter == 'all' ? true : user.role == _roleFilter;

      final matchesStatus = _statusFilter == 'all'
          ? true
          : _statusFilter == 'active'
              ? user.isActive
              : !user.isActive;

      final matchesDate = _dateFilterDays == null
          ? true
          : DateTime.now().difference(user.createdAt).inDays <=
              _dateFilterDays!;

      return matchesSearch && matchesRole && matchesStatus && matchesDate;
    }).toList();

    list.sort((a, b) {
      switch (_sortBy) {
        case 'join_date':
          return b.createdAt.compareTo(a.createdAt);
        case 'total_ads':
          return b.totalAdsPosted.compareTo(a.totalAdsPosted);
        case 'last_login':
          return b.lastLoginAt.compareTo(a.lastLoginAt);
        case 'name':
        default:
          final aName = (a.displayName ?? a.email).toLowerCase();
          final bName = (b.displayName ?? b.email).toLowerCase();
          return aName.compareTo(bName);
      }
    });

    return list;
  }

  void _toggleSelectionMode(String? initialId) {
    setState(() {
      _selectionMode = true;
      if (initialId != null) {
        _selectedUserIds.add(initialId);
      }
    });
  }

  void _enableSelectionMode() {
    setState(() {
      _selectionMode = true;
      _selectedUserIds.clear();
    });
  }

  void _disableSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedUserIds.clear();
      _isBulkWorking = false;
    });
  }

  void _toggleUserSelected(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
      if (_selectedUserIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  Future<void> _bulkSetActive(bool isActive) async {
    if (_selectedUserIds.isEmpty) return;
    setState(() => _isBulkWorking = true);
    final provider = context.read<AdminProvider>();
    for (final id in _selectedUserIds) {
      await provider.toggleUserStatus(id, isActive);
    }
    setState(() => _isBulkWorking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isActive ? 'Users activated' : 'Users deactivated'),
      ),
    );
  }

  Future<void> _bulkSetRole(String role) async {
    if (_selectedUserIds.isEmpty) return;
    setState(() => _isBulkWorking = true);
    final provider = context.read<AdminProvider>();
    for (final id in _selectedUserIds) {
      await provider.updateUserRole(id, role);
    }
    setState(() => _isBulkWorking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Role updated to ${role.replaceAll('_', ' ')}')),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'user':
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Today';
    }
  }
}
