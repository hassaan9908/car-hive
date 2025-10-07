import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../auth/loginscreen.dart';
import '../auth/auth_provider.dart';
import 'homepage.dart';



class Profilepage extends StatelessWidget {
  const Profilepage({super.key});

  static const int _selectedIndex = 4;
  static const List<String> _navRoutes = [
    '/', '/myads', '/upload', '/investment', '/profile'
  ];

  void _onTabSelected(BuildContext context, int index) {
    if (_selectedIndex == index) return;
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, _navRoutes[0], (route) => false);
    } else {
      Navigator.pushReplacementNamed(context, _navRoutes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: user info or login CTA
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: authProvider.isLoggedIn
                      ? _buildGreetingMessage(context, authProvider, colorScheme)
                      : _buildLoginButton(context, colorScheme),
                ),

                // Premium banner
                _buildPremiumBanner(context),
                const SizedBox(height: 16),

                // Settings section
                _sectionHeader(context, 'Settings'),
                _settingsCard(context, [
                  // Theme with current mode subtitle
                  Builder(builder: (context) {
                    final themeProvider = Provider.of<ThemeProvider>(context);
                    String subtitle;
                    switch (themeProvider.themeMode) {
                      case ThemeMode.light:
                        subtitle = 'Light';
                        break;
                      case ThemeMode.dark:
                        subtitle = 'Dark';
                        break;
                      default:
                        subtitle = 'System Default';
                    }
                    return _settingsTile(
                      context,
                      Icons.settings,
                      'Theme',
                      subtitle: subtitle,
                      onTap: () => _showThemeBottomSheet(context),
                    );
                  }),
                  _dividerInset(context),
                  _settingsTile(context, Icons.language, 'Choose Language', onTap: () {}),
                  _dividerInset(context),
                ]),

                const SizedBox(height: 16),

                // Products section (Sell/Buy)
                _sectionHeader(context, 'Products'),
                _settingsCard(context, [
                  _settingsTile(context, Icons.directions_car, 'Sell My Car', onTap: () => _navigateToUpload(context)),
                  _dividerInset(context),
                  _settingsTile(context, Icons.directions_car_filled, 'Buy Used Car', onTap: () => _navigateToUsedCars(context)),
                  _dividerInset(context),
                  _settingsTile(context, Icons.car_rental, 'Buy New Car', onTap: () => _navigateToNewCars(context)),
                ]),

                const SizedBox(height: 16),

                // Explore section
                _sectionHeader(context, 'Explore'),
                _settingsCard(context, [
                  _settingsTile(context, Icons.article, 'Blog', onTap: () {}),
                  _dividerInset(context),
                  _settingsTile(context, Icons.ondemand_video, 'Videos', onTap: () {}),
                  _dividerInset(context),
                  _settingsTile(context, Icons.directions_car, 'Cool Rides', onTap: () {}),
                ]),

                const SizedBox(height: 16),

                // More section
                _sectionHeader(context, 'More'),
                _settingsCard(context, [
                  _settingsTile(context, Icons.reviews_outlined, 'Rate & Review', onTap: () {}),
                  _dividerInset(context),
                  _settingsTile(context, Icons.help_outline, 'Help', onTap: () {}),
                ]),

                const SizedBox(height: 20),

                if (authProvider.isLoggedIn)
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showLogoutDialog(context, authProvider),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Log out'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
              ],
            ),
          ),
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

  Widget _buildLoginButton(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Loginscreen()),
        );
      },
      child: Container(
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 17),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Log in / Sign up',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingMessage(BuildContext context, AuthProvider authProvider, ColorScheme colorScheme) {
    final displayName = authProvider.getDisplayName();
    final email = authProvider.getEmail();
    
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 17),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: colorScheme.primary.withOpacity(0.12),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // Greeting message
            Text(
              'Welcome',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            
            // Username
            Text(
              displayName.isNotEmpty ? displayName : 'User',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Email (if different from display name)
            if (email.isNotEmpty && email != displayName)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  email,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.signOut();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 0, 6),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
            fontSize: 16,
          ),
        ),
      );

  // Modern card container for grouped settings
  Widget _settingsCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      ),
    );
  }

  // Single settings tile with trailing chevron
  Widget _settingsTile(BuildContext context, IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }

  // Thin divider with left inset to align with text
  Widget _dividerInset(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.3)),
    );
  }

  // Premium banner like the screenshot
  Widget _buildPremiumBanner(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          cs.primary,
          cs.primaryContainer,
        ]),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: const [
          Icon(Icons.workspace_premium, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Premium Membership',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Upgrade for more features',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final currentMode = themeProvider.themeMode;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: currentMode,
              title: const Text('System Default'),
              onChanged: (mode) {
                themeProvider.setThemeMode(mode!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: currentMode,
              title: const Text('Light'),
              onChanged: (mode) {
                themeProvider.setThemeMode(mode!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: currentMode,
              title: const Text('Dark'),
              onChanged: (mode) {
                themeProvider.setThemeMode(mode!);
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToUpload(BuildContext context) {
    Navigator.pushNamed(context, '/upload');
  }

  void _navigateToUsedCars(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const Homepage(initialTab: 0),
      ),
      (route) => false,
    );
  }

  void _navigateToNewCars(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const Homepage(initialTab: 1),
      ),
      (route) => false,
    );
  }
}