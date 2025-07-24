import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return false;
      },
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Gradient header with button
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 96, 24, 114),
                    Color.fromARGB(255, 132, 33, 156),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  height: 45,
                  margin: EdgeInsets.only(left: 17, right: 17, top: 70),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Log in / Sign up',
                      style: TextStyle(
                        color: Color.fromARGB(255, 132, 33, 156),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Section: Personal
            _sectionHeader(context, "Personal"),
            _profileTile(context, Icons.settings, "Theme"),
            _profileTile(context, Icons.language, "Choose Language"),
            Divider(),
            // Section: Products
            _sectionHeader(context, "Products"),
            _profileTile(context, Icons.directions_car, "Sell My Car"),
            _profileTile(context, Icons.directions_car_filled, "Buy Used Car"),
            _profileTile(context, Icons.car_rental, "Buy New Car"),
            Divider(),
            // Section: Explore
            _sectionHeader(context, "Explore"),
            _profileTile(context, Icons.article, "Blog"),
            _profileTile(context, Icons.ondemand_video, "Videos"),
            _profileTile(context, Icons.directions_car, "Cool Rides"),
          ],
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
        title: Text(title, style: TextStyle(fontSize: 16)),
        subtitle: Text(subtitle),
        onTap: () => _showThemeBottomSheet(context),
        dense: true,
      );
    }
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: TextStyle(fontSize: 16)),
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
              title: Text('System Default'),
              onChanged: (mode) {
                themeProvider.setThemeMode(mode!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: currentMode,
              title: Text('Light'),
              onChanged: (mode) {
                themeProvider.setThemeMode(mode!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: currentMode,
              title: Text('Dark'),
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