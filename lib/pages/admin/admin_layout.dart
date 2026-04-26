import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import 'admin_ads_page.dart';
import 'admin_announcement_banners_page.dart';
import 'admin_blog_management_page.dart';
import 'admin_blog_upload_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_fuel_prices_page.dart';
import 'admin_insight_metrics_page.dart';
import 'admin_reschedule_requests_page.dart';
import 'admin_theme.dart';
import 'admin_users_page.dart';
import 'admin_video_management_page.dart';
import 'admin_video_upload_page.dart';
import 'admin_visit_schedule_page.dart';

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
      id: 'dashboard',
      title: 'Dashboard',
      icon: Icons.dashboard,
      builder: (_) => const AdminDashboardPage(),
    ),
    AdminNavigationItem(
      id: 'insight_metrics',
      title: 'Insight Metrics',
      icon: Icons.insights,
      builder: (_) => const AdminInsightMetricsPage(),
    ),
    AdminNavigationItem(
      id: 'ad_moderation',
      title: 'Ad Moderation',
      icon: Icons.rate_review,
      builder: (_) => const AdminAdsPage(),
    ),
    AdminNavigationItem(
      id: 'user_management',
      title: 'User Management',
      icon: Icons.people,
      builder: (_) => const AdminUsersPage(),
    ),
    AdminNavigationItem(
      id: 'announcements',
      title: 'Announcements',
      icon: Icons.campaign,
      builder: (_) => const AdminAnnouncementBannersPage(),
    ),
    AdminNavigationItem(
      id: 'fuel_prices',
      title: 'Fuel Prices',
      icon: Icons.local_gas_station,
      builder: (_) => const AdminFuelPricesPage(),
    ),
    AdminNavigationItem(
      id: 'visit_schedules',
      title: 'Visit Schedules',
      icon: Icons.edit_calendar_outlined,
      builder: (_) => const AdminVisitSchedulePage(),
    ),
    AdminNavigationItem(
      id: 'visit_requests',
      title: 'Visit Requests',
      icon: Icons.swap_horiz_outlined,
      builder: (_) => const AdminRescheduleRequestsPage(),
    ),
    AdminNavigationItem(
      id: 'upload_blog',
      title: 'Upload Blog',
      icon: Icons.article,
      builder: (_) => const AdminBlogUploadPage(),
    ),
    AdminNavigationItem(
      id: 'upload_video',
      title: 'Upload Video',
      icon: Icons.video_library,
      builder: (_) => const AdminVideoUploadPage(),
    ),
    AdminNavigationItem(
      id: 'manage_blogs',
      title: 'Manage Blogs',
      icon: Icons.manage_accounts,
      builder: (_) => const AdminBlogManagementPage(),
    ),
    AdminNavigationItem(
      id: 'manage_videos',
      title: 'Manage Videos',
      icon: Icons.slideshow,
      builder: (_) => const AdminVideoManagementPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final pageBackground = AdminThemeTokens.pageBackground(context);
    final pageSurface = AdminThemeTokens.pageSurface(context);
    final pageBorder = AdminThemeTokens.pageBorder(context);
    final selectedItem = _navigationItems[_selectedIndex];

    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return Scaffold(
          backgroundColor: pageBackground,
          body: SafeArea(
            child: Row(
              children: [
                _buildSidebar(context, adminProvider, accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Container(
                        key: ValueKey(selectedItem.id),
                        decoration: BoxDecoration(
                          color: pageSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: pageBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Theme(
                          data: theme.copyWith(
                            scaffoldBackgroundColor: pageBackground,
                            canvasColor: pageBackground,
                          ),
                          child: selectedItem.builder(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    AdminProvider adminProvider,
    Color accent,
  ) {
    final sidebarBackground = AdminThemeTokens.sidebarBackground(context);
    final sidebarBorder = AdminThemeTokens.sidebarBorder(context);
    final sidebarText = AdminThemeTokens.sidebarPrimaryText(context);
    final sidebarSecondaryText = AdminThemeTokens.sidebarSecondaryText(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: _isSidebarCollapsed ? 76 : 260,
      margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: sidebarBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: sidebarBorder),
        boxShadow: [
          BoxShadow(
            color: AdminThemeTokens.sidebarShadow(context),
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
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sidebarBorder),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CarHive',
                          style: TextStyle(
                            color: sidebarText,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Admin Console',
                          style: TextStyle(
                            color: sidebarSecondaryText,
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
                    color: sidebarText,
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
          Divider(color: sidebarBorder, height: 1),
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

                return _NavItem(
                  title: item.title,
                  icon: item.icon,
                  isCollapsed: _isSidebarCollapsed,
                  isSelected: _selectedIndex == index,
                  accent: accent,
                  textColor: sidebarText,
                  mutedTextColor: sidebarSecondaryText,
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
        color: AdminThemeTokens.sidebarHover(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminThemeTokens.sidebarBorder(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withValues(alpha: 0.18),
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
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
                    style: TextStyle(
                      color: AdminThemeTokens.sidebarPrimaryText(context),
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    (admin?.role ?? 'ADMIN').replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: AdminThemeTokens.sidebarSecondaryText(context),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.logout,
                color: AdminThemeTokens.sidebarSecondaryText(context),
                size: 20,
              ),
              tooltip: 'Logout',
              onPressed: () async {
                await adminProvider.adminLogout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ],
      ),
    );
  }
}

class AdminNavigationItem {
  final String id;
  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  const AdminNavigationItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
  });
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.title,
    required this.icon,
    required this.isCollapsed,
    required this.isSelected,
    required this.accent,
    required this.textColor,
    required this.mutedTextColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isCollapsed;
  final bool isSelected;
  final Color accent;
  final Color textColor;
  final Color mutedTextColor;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = AdminThemeTokens.sidebarHover(context);
    final activeBackground = AdminThemeTokens.sidebarActiveBackground(context);
    final activeBorder = AdminThemeTokens.sidebarActiveBorder(context);
    final baseColor = widget.isSelected
        ? widget.accent
        : (_hovering ? widget.textColor : widget.mutedTextColor);

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
              ? activeBackground
              : _hovering
                  ? hoverColor
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: widget.isSelected ? Border.all(color: activeBorder) : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          splashColor: hoverColor,
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
                Icon(Icons.chevron_right,
                    size: 18, color: widget.mutedTextColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
