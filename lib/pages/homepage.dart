import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../components/custom_textfield.dart';
import '../components/car_tabs.dart';
import '../components/custom_bottom_nav.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  static const int _selectedIndex = 0;
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CarHive',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: colorScheme.primary,
        centerTitle: true,
        actions: [
          // Admin Panel button (web only)
          if (kIsWeb)
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
              icon: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
              ),
              tooltip: 'Admin Panel',
            ),
          // Debug button (web only)
          if (kIsWeb)
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin-debug');
              },
              icon: const Icon(
                Icons.bug_report,
                color: Colors.orange,
              ),
              tooltip: 'Admin Debug',
            ),
          // Theme Showcase button (web only)
          if (kIsWeb)
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/theme-showcase');
              },
              icon: const Icon(
                Icons.palette,
                color: Colors.purple,
              ),
              tooltip: 'Theme Showcase',
            ),
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
              icon: const Icon(
                Icons.chat,
                color: Colors.white,
              )),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.background,
              colorScheme.surfaceVariant,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: CustomTextField(
                hintText: 'Search cars, brands, models.',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 16),
            CarTabs(),
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
    );
  }
}
