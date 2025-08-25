import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../auth/loginscreen.dart';
import '../auth/auth_service.dart';
import '../auth/auth_provider.dart';

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
        body: SafeArea(
          child: Column(
            children: [
              // Gradient header with login button or greeting
              Container(
                height: 160,
                color: Theme.of(context).colorScheme.primary,
                child: Center(
                  child: authProvider.isLoggedIn
                      ? _buildGreetingMessage(context, authProvider, colorScheme)
                      : _buildLoginButton(context, colorScheme),
                ),
              ),
              
              // Scrollable content area
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Section: Personal
                    _sectionHeader(context, "Personal"),
                    _profileTile(context, Icons.settings, "Theme"),
                    _profileTile(context, Icons.language, "Choose Language"),
                    const Divider(),
                    
                    // Section: Products
                    _sectionHeader(context, "Products"),
                    _profileTile(context, Icons.directions_car, "Sell My Car"),
                    _profileTile(context, Icons.directions_car_filled, "Buy Used Car"),
                    _profileTile(context, Icons.car_rental, "Buy New Car"),
                    const Divider(),
                    
                    // Section: Explore
                    _sectionHeader(context, "Explore"),
                    _profileTile(context, Icons.article, "Blog"),
                    _profileTile(context, Icons.ondemand_video, "Videos"),
                    _profileTile(context, Icons.directions_car, "Cool Rides"),

                    // Logout button (only show when logged in)
                    if (authProvider.isLoggedIn)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () => _showLogoutDialog(context, authProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Log out",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // Add bottom padding to ensure content doesn't get cut off
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Log in / Sign up',
            style: TextStyle(
              color: Color.fromARGB(255, 35, 38, 68),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingMessage(BuildContext context, AuthProvider authProvider, ColorScheme colorScheme) {
    final displayName = authProvider.getDisplayName();
    final email = authProvider.getEmail();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // User avatar
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 35, 38, 68),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Greeting message
          Text(
            'Welcome back,',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          
          // Username
          Text(
            displayName.isNotEmpty ? displayName : 'User',
            style: const TextStyle(
              color: Colors.white,
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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ),
        ],
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

  Widget _profileTile(BuildContext context, IconData icon, String title) {
    if (title == "Theme") {
      final themeProvider = Provider.of<ThemeProvider>(context);
      String subtitle;
      switch (themeProvider.themeMode) {
        case ThemeMode.light:
          subtitle = "Light";
          break;
        case ThemeMode.dark:
          subtitle = "Dark";
          break;
        default:
          subtitle = "System Default";
      }
      return ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        subtitle: Text(subtitle),
        onTap: () => _showThemeBottomSheet(context),
        dense: true,
      );
    }
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () {},
      dense: true,
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
}