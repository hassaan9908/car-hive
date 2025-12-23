import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'admin_dashboard_page.dart';
import 'admin_ads_page.dart';
import 'admin_users_page.dart';
import 'admin_blog_upload_page.dart';
import 'admin_video_upload_page.dart';
import 'admin_blog_management_page.dart';
import 'admin_video_management_page.dart';
import 'admin_insight_metrics_page.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  final List<AdminNavigationItem> _navigationItems = [
    AdminNavigationItem(
      title: 'Dashboard',
      icon: Icons.dashboard,
      page: const AdminDashboardPage(),
    ),
    AdminNavigationItem(
      title: 'Insight Metrics',
      icon: Icons.insights,
      page: const AdminInsightMetricsPage(),
    ),
    AdminNavigationItem(
      title: 'Ad Moderation',
      icon: Icons.rate_review,
      page: const AdminAdsPage(),
    ),
    AdminNavigationItem(
      title: 'User Management',
      icon: Icons.people,
      page: const AdminUsersPage(),
    ),
    AdminNavigationItem(
      title: 'Upload Blog',
      icon: Icons.article,
      page: const AdminBlogUploadPage(),
    ),
    AdminNavigationItem(
      title: 'Upload Video',
      icon: Icons.video_library,
      page: const AdminVideoUploadPage(),
    ),
    AdminNavigationItem(
      title: 'Manage Blogs',
      icon: Icons.manage_accounts,
      page: const AdminBlogManagementPage(),
    ),
    AdminNavigationItem(
      title: 'Manage Videos',
      icon: Icons.slideshow,
      page: const AdminVideoManagementPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = const Color(0xFFF48C25);
    final canvasStart =
        isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F8FB);
    final canvasEnd = isDark ? const Color(0xFF111827) : Colors.white;
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return Scaffold(
          backgroundColor: canvasStart,
          body: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [canvasStart, canvasEnd],
                ),
              ),
              child: Row(
                children: [
                  _buildSidebar(context, adminProvider, isDark, accent),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: Container(
                                key: ValueKey(_selectedIndex),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.02)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.grey.shade200,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 18,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _navigationItems[_selectedIndex].page,
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
          ),
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context, AdminProvider adminProvider,
      bool isDark, Color accent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: _isSidebarCollapsed ? 76 : 260,
      margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF1F2937),
                  const Color(0xFF111827),
                ]
              : [
                  const Color(0xFF152032),
                  const Color(0xFF0E1624),
                ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 8 : 18),
            child: Row(
              children: [
                if (!_isSidebarCollapsed) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'CarHive',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Admin Console',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _isSidebarCollapsed ? Icons.menu_open : Icons.menu,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() {
                    _isSidebarCollapsed = !_isSidebarCollapsed;
                  }),
                  tooltip: _isSidebarCollapsed ? 'Expand' : 'Collapse',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                vertical: 6,
                horizontal: _isSidebarCollapsed ? 8 : 14,
              ),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == index;

                return _NavItem(
                  title: item.title,
                  icon: item.icon,
                  isCollapsed: _isSidebarCollapsed,
                  isSelected: isSelected,
                  accent: accent,
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? 8 : 14,
              vertical: 8,
            ),
            child: MediaQuery.of(context).size.width >= 1220
                ? _buildUserCard(context, adminProvider, accent)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AdminProvider adminProvider,
    Color accent,
  ) {
    return const SizedBox.shrink();
  }

  Widget _buildUserCard(
    BuildContext context,
    AdminProvider adminProvider,
    Color accent,
  ) {
    final admin = adminProvider.currentAdmin;
    final initials = (admin?.displayName?.isNotEmpty == true
            ? admin!.displayName![0]
            : admin?.email[0] ?? 'A')
        .toUpperCase();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(_isSidebarCollapsed ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withOpacity(0.18),
            child: Text(
              initials,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (!_isSidebarCollapsed) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin?.displayName ?? 'Admin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    (admin?.role ?? 'ADMIN').replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
              tooltip: 'Logout',
              onPressed: () async {
                await adminProvider.adminLogout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
          ]
        ],
      ),
    );
  }
}

class AdminNavigationItem {
  final String title;
  final IconData icon;
  final Widget page;

  AdminNavigationItem({
    required this.title,
    required this.icon,
    required this.page,
  });
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.title,
    required this.icon,
    required this.isCollapsed,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isCollapsed;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isSelected
        ? widget.accent
        : Colors.white.withOpacity(_hovering ? 0.9 : 0.68);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCollapsed ? 12 : 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? Colors.white.withOpacity(0.08)
              : _hovering
                  ? Colors.white.withOpacity(0.04)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: widget.isSelected
              ? Border.all(color: Colors.white.withOpacity(0.12))
              : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          splashColor: Colors.white.withOpacity(0.06),
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Icon(widget.icon, color: baseColor, size: 20),
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: baseColor,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: Colors.white54),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
