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
    
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return Scaffold(
          body: Row(
            children: [
              // Sidebar
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isSidebarCollapsed ? 70 : 250,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFFf48c25).withOpacity(0.9),
                            const Color(0xFFd97706),
                          ]
                        : [
                            const Color(0xFFf48c25),
                            const Color(0xFFf48c25).withOpacity(0.8),
                          ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          if (!_isSidebarCollapsed) ...[
                            const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'CarHive Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          IconButton(
                            icon: Icon(
                              _isSidebarCollapsed
                                  ? Icons.menu_open
                                  : Icons.menu,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isSidebarCollapsed = !_isSidebarCollapsed;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),

                    // Navigation Items
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _navigationItems.length,
                        itemBuilder: (context, index) {
                          final item = _navigationItems[index];
                          final isSelected = _selectedIndex == index;

                          return ListTile(
                            leading: Icon(
                              item.icon,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                            title: _isSidebarCollapsed
                                ? null
                                : Text(
                                    item.title,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                            selected: isSelected,
                            selectedTileColor: Colors.white.withOpacity(0.1),
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                          );
                        },
                      ),
                    ),

                    // User Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 16),
                          if (!_isSidebarCollapsed) ...[
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Text(
                                (adminProvider.currentAdmin?.displayName
                                                ?.isNotEmpty ==
                                            true
                                        ? adminProvider
                                            .currentAdmin!.displayName![0]
                                        : adminProvider
                                                .currentAdmin?.email[0] ??
                                            'A')
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              adminProvider.currentAdmin?.displayName ??
                                  'Admin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              adminProvider.currentAdmin?.role
                                      .replaceAll('_', ' ')
                                      .toUpperCase() ??
                                  'ADMIN',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                          ],
                          IconButton(
                            icon:
                                const Icon(Icons.logout, color: Colors.white70),
                            onPressed: () async {
                              await adminProvider.adminLogout();
                              if (mounted) {
                                Navigator.pushReplacementNamed(context, '/');
                              }
                            },
                            tooltip: _isSidebarCollapsed ? 'Logout' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              const Color(0xFF221910),
                              const Color(0xFF221910),
                            ]
                          : [
                              Colors.grey.shade400,
                              Colors.white,
                            ],
                    ),
                  ),
                  child: _navigationItems[_selectedIndex].page,
                ),
              ),
            ],
          ),
        );
      },
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

