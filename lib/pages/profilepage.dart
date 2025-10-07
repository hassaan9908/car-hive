import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../components/custom_bottom_nav.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../auth/loginscreen.dart';
import '../auth/auth_provider.dart';
import 'homepage.dart';
import 'edit_profile_page.dart';

class Profilepage extends StatelessWidget {
  const Profilepage({super.key});

  static const int _selectedIndex = 4;
  static const List<String> _navRoutes = [
    '/',
    '/myads',
    '/upload',
    '/investment',
    '/profile'
  ];

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
                      ? _buildGreetingMessage(
                          context, authProvider, colorScheme)
                      : _buildLoginButton(context, colorScheme),
                ),
              ),

              // Scrollable content area
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (authProvider.isLoggedIn) _buildTrustSection(context),
                    // Section: Personal
                    _sectionHeader(context, "Personal"),
                    if (authProvider.isLoggedIn)
                      _profileTile(context, Icons.edit, "Edit Profile"),
                    _profileTile(context, Icons.settings, "Theme"),
                    _profileTile(context, Icons.language, "Choose Language"),
                    const Divider(),

                    // Section: Products
                    _sectionHeader(context, "Products"),
                    _profileTile(context, Icons.directions_car, "Sell My Car"),
                    _profileTile(
                        context, Icons.directions_car_filled, "Buy Used Car"),
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
                          onPressed: () =>
                              _showLogoutDialog(context, authProvider),
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

  Widget _buildTrustSection(BuildContext context) {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Handle loading state to prevent flicker
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() ?? <String, dynamic>{};
        double asDouble(dynamic v) {
          if (v is num) return v.toDouble();
          if (v is String) return double.tryParse(v) ?? 0;
          return 0;
        }

        int asInt(dynamic v) {
          if (v is int) return v;
          if (v is num) return v.toInt();
          if (v is String) return int.tryParse(v) ?? 0;
          return 0;
        }

        final String level = (data['trustLevel'] ?? 'Bronze').toString();
        final double score = asDouble(data['trustScore']);
        final double profileCompleteness =
            asDouble(data['profileCompleteness']);
        final double responsiveness = asDouble(data['responsivenessScore']);
        final double avgRating = asDouble(data['averageRating']);
        final int totalSales = asInt(data['totalSales']);

        final List<String> tips = [];
        if ((data['displayName'] ?? '').toString().isEmpty)
          tips.add('Add your display name');
        if ((data['phoneNumber'] ?? '').toString().isEmpty)
          tips.add('Add your phone number');
        if (profileCompleteness < 100) tips.add('Complete your profile');
        if (avgRating <= 0) tips.add('Invite buyers to leave reviews');
        if (totalSales <= 0) tips.add('Complete your first sale');
        if (responsiveness < 80) tips.add('Respond to messages quickly');

        Color badgeColor;
        switch (level) {
          case 'Gold':
            badgeColor = Colors.amber[700] ?? Colors.amber;
            break;
          case 'Silver':
            badgeColor = Colors.blueGrey[400] ?? Colors.blueGrey;
            break;
          default:
            badgeColor = Colors.brown[400] ?? Colors.brown;
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (level).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('Score: ${score.toStringAsFixed(0)}'),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _metricChip(context,
                        'Profile ${profileCompleteness.toStringAsFixed(0)}%'),
                    _metricChip(
                        context, 'Rating ${avgRating.toStringAsFixed(1)}/5'),
                    _metricChip(context, 'Sales $totalSales'),
                    _metricChip(context,
                        'Response ${responsiveness.toStringAsFixed(0)}%'),
                  ],
                ),
                if (tips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Improve your TrustRank:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  for (final tip in tips.take(4))
                    Row(
                      children: [
                        const Icon(Icons.arrow_right, size: 18),
                        const SizedBox(width: 4),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metricChip(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
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

  Widget _buildGreetingMessage(BuildContext context, AuthProvider authProvider,
      ColorScheme colorScheme) {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 17),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: const Text(
                    'U',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 35, 38, 68),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final username = (data['username'] ?? '').toString();
        final fullName = (data['fullName'] ?? '').toString();
        final displayName = (data['displayName'] ?? '').toString();
        final email = (data['email'] ?? '').toString();

        // Use username if available, otherwise fall back to fullName or displayName
        final mainName = username.isNotEmpty
            ? '@$username'
            : (fullName.isNotEmpty
                ? fullName
                : displayName.isNotEmpty
                    ? displayName
                    : 'User');

        // Use first character of the main name for avatar
        final avatarChar =
            mainName.isNotEmpty ? mainName[0].toUpperCase() : 'U';

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
                  avatarChar,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 35, 38, 68),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Username (main display)
              Text(
                mainName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Email below username
              if (email.isNotEmpty)
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
      },
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
    if (title == "Edit Profile") {
      return ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditProfilePage()),
        ),
        dense: true,
      );
    }
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

    // Handle Products section navigation
    if (title == "Sell My Car") {
      return ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        onTap: () => _navigateToUpload(context),
        dense: true,
      );
    }

    if (title == "Buy Used Car") {
      return ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        onTap: () => _navigateToUsedCars(context),
        dense: true,
      );
    }

    if (title == "Buy New Car") {
      return ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        onTap: () => _navigateToNewCars(context),
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

  void _navigateToUpload(BuildContext context) {
    Navigator.pushNamed(context, '/upload');
  }

  void _navigateToUsedCars(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const Homepage(initialTab: 0), // Used Cars tab
      ),
      (route) => false,
    );
  }

  void _navigateToNewCars(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const Homepage(initialTab: 1), // New Cars tab
      ),
      (route) => false,
    );
  }
}
